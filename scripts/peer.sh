#!/bin/bash
#
# Copyright 2020 Yiwenlong(wlong.yi#gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
WORK_HOME=$(pwd)

DAEMON_SUPPORT_SCRIPT="$DIR/daemon-support/config-daemon.sh"

ORG_CONFIGTX_TEMPLATE_FILE="$DIR/template/configtx-peer.yaml"
DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH="$DIR/chaincode-builder"

# shellcheck source=utils/log-utils.sh
. "$DIR/utils/log-utils.sh"
# shellcheck source=utils/conf-utils.sh
. "$DIR/utils/conf-utils.sh"
# shellcheck source=utils/file-utils.sh
. "$DIR/utils/file-utils.sh"

function readConfOrgValue() {
  readConfValue "$CONF_FILE" org "$1"; echo
}

function readConfPeerValue() {
  readConfValue "$CONF_FILE" "$1" "$2"; echo
}

function configNode {
  org_name=$1
  node_name=$2
  org_domain=$3
  org_mspid=$4
  logInfo "Start config node:" "$org_name.$node_name"
  node_domain=$node_name.$org_domain

  org_home="$WORK_HOME/$org_name"
  node_home="$org_home/$node_name"
  if [ -d "$node_home" ]; then
    logError "Working directory already exists!!" "$node_home"
    exit 1
  fi
  mkdir -p "$node_home" && cd "$node_home" || exit
  logInfo "Node work home:" "$node_home"

  cp -r "$DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH" "$node_home/my_external_builder"
  cp -r "$org_home/crypto-config/peerOrganizations/$org_domain/peers/$node_domain/"* "$node_home"

  if ! "$DIR/config-yaml-core.sh" -f "$CONF_FILE" -d "$node_home" -n "$node_name"; then
    exit $?
  fi
  command=$(readConfPeerValue "$node_name" "node.command.binary")
  command=$(absolutefile "$command" "$WORK_HOME")
  if [ -f "$command" ]; then
    logInfo "Node binary file:" "$command"
    cp "$command" "$node_home/"
  else
    logError "Warming: no peer command binary found!!!" "$command"
  fi

  daemon=$(readConfPeerValue "$node_name" "node.daemon.type")
  node_process_name="FABRIC-NODOCKER-$org_name-$node_name"
  if ! "$DAEMON_SUPPORT_SCRIPT" -d "$daemon" -n "$node_process_name" -h "$node_home" -c "peer node start"; then
    exit $?
  fi
  logSuccess "Node config success:" "$node_name"
}

function config {
  org_name=$(readConfOrgValue 'org.name')
  org_mspid=$(readConfOrgValue 'org.mspid')
  org_domain=$(readConfOrgValue 'org.domain')
  org_node_count=$(readConfOrgValue 'org.node.count')
  org_user_count=$(readConfOrgValue 'org.user.count')
  org_anchor_peers=$(readConfOrgValue 'org.anchor.peers')

  logInfo "Start config organization: " "$org_name"
  logInfo "Organization mspid:" "$org_mspid"
  logInfo "Organization domain:" "$org_domain"
  logInfo "Organization node count:" "$org_node_count"
  logInfo "Organization user count:" "$org_user_count"
  logInfo "Organization anchor peer:" "$org_anchor_peers"

  org_home="$WORK_HOME/$org_name"
  if [ -d "$org_home" ]; then
    logError "Working directory already exists!! $node_home"
    exit 1
  fi
  mkdir -p "$org_home" && cd "$org_home" || exit
  logInfo "Organization work home:" "$org_home"

  cp "$CONF_FILE" "$org_home/conf.ini"
  # generate org msp config files.
  if ! "$DIR/config-msp.sh" -t peer -d "$org_home" -f "$CONF_FILE"; then
    exit $?
  fi

  org_msp_dir="$org_home/crypto-config/peerOrganizations/$org_domain/msp"
  configtx_file="$org_home/configtx-org.yaml"
  sed -e "s/<org.name>/${org_name}/
  s/<org.mspid>/${org_mspid}/
  s/<org.mspid>/${org_mspid}/
  s/<org.mspid>/${org_mspid}/
  s:<org.msp.dir>:${org_msp_dir}:" "$ORG_CONFIGTX_TEMPLATE_FILE" > "$configtx_file"
  # append anchor peers.
  for peer_name in $org_anchor_peers; do
    anchor_peer_host=$(readConfPeerValue "$peer_name" "node.access.host")
    anchor_peer_port=$(readConfPeerValue "$peer_name" "node.access.port")
    if [ -n "$anchor_peer_host" ] && [ -n "$anchor_peer_port" ] ; then
      echo "            - Host: $anchor_peer_host" >> "$configtx_file"
      echo "              Port: $anchor_peer_port" >> "$configtx_file"
    fi
  done

  logSuccess "Organization configtx config file generated:" "$configtx_file"

  for (( i = 0; i < "$org_node_count" ; ++i)); do
    configNode "$org_name" "peer$i" "$org_domain" "$org_mspid"
  done
}

function usage {
  echo "USAGE:"
  echo "  peer.sh <command> [ -f configfile | -o orgName ]"
  echo "      command: [ configorg | startorg | stoporg | startnode | stropnode | usage]"
}

if [ ! "$FABRIC_BIN" ]; then
  logError "Missing environment variable: " "FABRIC_BIN"
  exit 1
fi

COMMAND=$1
if [ ! "$COMMAND" ]; then
  usage
  exit 1
fi
shift

while getopts f:d: opt
do 
  case $opt in
    f) CONF_FILE=$(absolutefile "$OPTARG" "$WORK_HOME")
      checkfileexist "$CONF_FILE"
      ;;
    d) CONF_DIR=$(absolutefile "$OPTARG" "$WORK_HOME")
      checkdirexist "$CONF_DIR"
      ;;
    *) usage; exit 1;;
  esac
done 

case $COMMAND in 
  configorg)
    checkfileexist "$ORG_CONFIGTX_TEMPLATE_FILE"
    checkdirexist "$DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH"
    config
    ;;
esac

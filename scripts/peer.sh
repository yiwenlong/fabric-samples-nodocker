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

ORG_CONFIGTX_TEMPLATE_FILE=$DIR/template/configtx-peer.yaml
DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH=$DIR/chaincode-builder
COMMAND_PEER=$FABRIC_BIN/peer

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

function checkSuccess() {
    if [[ $? != 0 ]]; then
        exit $?
    fi
}

function configNode {
  org_name=$1
  node_name=$2
  org_domain=$3
  org_mspid=$4
  logInfo "Start config node:" "$org_name.$node_name"
  node_port=$(readConfPeerValue "$node_name" node.port)
  node_chaincode_port=$(readConfPeerValue "$node_name" node.chaincode.port)
  node_operations_port=$(readConfPeerValue "$node_name" node.operations.port)
  node_gossip_node=$(readConfPeerValue "$node_name" node.gossip)
  node_domain=$node_name.$org_domain
  logInfo "Node port:" "$node_port"
  logInfo "Node chaincode port:" "$node_chaincode_port"
  logInfo "Node operations port:" "$node_operations_port"
  logInfo "Node gossip node:" "$node_gossip_node"
  logInfo "Node domain:" "$node_domain"

  org_home=$WORK_HOME/$org_name
  node_home=$org_home/$node_name
  if [ -d "$node_home" ]; then
      rm -fr "$node_home"
  fi
  mkdir -p "$node_home" && cd "$node_home"
  logInfo "Node work home:" "$node_home"

  cp -r "$DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH" "$node_home/my_external_builder"
  cp -r "$org_home/crypto-config/peerOrganizations/$org_domain/peers/$node_domain/"* "$node_home"

  "$DIR/config-yaml-core.sh" -f "$CONF_FILE" -d "$node_home" -n "$node_name"
  checkSuccess

  supervisor_process_name="FABRIC-NODOCKER-$org_name-$node_name"
  "$DIR/config-supervisor.sh" -n "$supervisor_process_name" -h "$node_home" -c "$COMMAND_PEER node start"
  checkSuccess

  "$DIR/config-script.sh" -n "$supervisor_process_name" -h "$node_home"
  checkSuccess

  logSuccess "Node config success:" "$node_name"
}

function config {
  org_name=$(readConfOrgValue 'org.name')
  org_mspid=$(readConfOrgValue 'org.mspid')
  org_domain=$(readConfOrgValue 'org.domain')
  org_node_count=$(readConfOrgValue 'org.node.count')
  org_user_count=$(readConfOrgValue 'org.user.count')
  org_anchor_peer=$(readConfOrgValue 'org.anchor.peer')

  logInfo "Start config organization: " "$org_name"
  logInfo "Organization mspid:" "$org_mspid"
  logInfo "Organization domain:" "$org_domain"
  logInfo "Organization node count:" "$org_node_count"
  logInfo "Organization user count:" "$org_user_count"
  logInfo "Organization anchor peer:" "$org_anchor_peer"

  org_home=$WORK_HOME/$org_name
  if [ -d "$org_home" ]; then
    rm -fr "$org_home"
  fi
  mkdir -p "$org_home" && cd "$org_home"
  logInfo "Organization work home:" "$org_home"

  cp "$CONF_FILE" "$org_home/conf.ini"
  # generate org msp config files.
  "$DIR/config-msp.sh" -t peer -d "$org_home" -f "$CONF_FILE"
  checkSuccess

  org_msp_dir=$org_home/crypto-config/peerOrganizations/$org_domain/msp
  org_anchor_peeer_host=$org_anchor_peer.$org_domain
  org_anchor_peeer_port=$(readConfPeerValue $org_anchor_peer node.port)
  configtx_file=$org_home/configtx-org.yaml
  sed -e "s/<org.name>/${org_name}/
  s/<org.mspid>/${org_mspid}/
  s/<org.mspid>/${org_mspid}/
  s/<org.mspid>/${org_mspid}/
  s:<org.msp.dir>:${org_msp_dir}:
  s/<org.anchor.host>/${org_anchor_peeer_host}/
  s/<org.anchor.port>/${org_anchor_peeer_port}/" "$ORG_CONFIGTX_TEMPLATE_FILE" > "$configtx_file"
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

CONF_FILE=
CONF_DIR=

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
  startorg)
    if [ "$CONF_DIR" ]; then
        cd "$CONF_DIR"
    fi
    for node_name in $(ls . | grep peer); do
      sh "$node_name"/boot.sh
      if [ $? -eq 0 ]; then
          logSuccess "Node started:" "$node_name"
      fi
    done
    sleep 3
    logSuccess "Orgnaization all node started:" $(pwd)
    ;;
  startnode)
    if [ "$CONF_DIR" ]; then
      cd "$CONF_DIR"
    fi
    if [ -f boot.sh ]; then
      sh boot.sh
      if [ $? -eq 0 ]; then
        logSuccess "Node started:" $(pwd)
      fi
    else
      logError "Script file not found:" boot.sh
    fi
    ;;
  stoporg)
    if [ "$CONF_DIR" ]; then
      cd "$CONF_DIR"
    fi
    for node_name in $(ls . | grep peer); do
      sh "$node_name"/stop.sh
      if [ $? -eq 0 ]; then
        logSuccess "Node stop:" "$node_name"
      fi
    done
    logSuccess "Organization all node stop:" $(pwd)
    ;;
  stopnode)
    if [ "$CONF_DIR" ]; then
      cd "$CONF_DIR"
    fi
    if [ -f stop.sh ]; then
      sh stop.sh
      if [ $? -eq 0 ]; then
        logSuccess "Node stop:" $(pwd)
      fi
    fi
    ;;
esac 

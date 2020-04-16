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

CRYPTO_CONFIG_TEMPLATE_FILE=$DIR/template/crypto-config-peer.yaml
ORG_CONFIGTX_TEMPLATE_FILE=$DIR/template/configtx-peer.yaml
CORE_TEMPLATE_FILE=$DIR/template/core.yaml

DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH=$DIR/chaincode-builder
CHAINCODE_EXTERNAL_BUILDER_NAME=my_external_builder
CHAINCODE_EXTERNAL_BUILDER_PATH=my_external_builder

COMMAND_CRYPTOGEN=$FABRIC_BIN/cryptogen
COMMAND_PEER=$FABRIC_BIN/peer

. $DIR/utils/log-utils.sh
. $DIR/utils/conf-utils.sh
. $DIR/utils/file-utils.sh

function readConfOrgValue() {
    echo $(readConfValue $CONF_FILE 'org' $1)
}

function readConfPeerValue() {
    echo $(readConfValue $CONF_FILE $1 $2)
}

function configNode {
  org_name=$1
  node_name=$2
  org_domain=$3
  org_mspid=$4
  logInfo "Start config node:" "$org_name.$node_name"
  node_port=$(readConfPeerValue "$node_name" peer.port)
  node_chaincode_port=$(readConfPeerValue "$node_name" peer.chaincode.port)
  node_operations_port=$(readConfPeerValue "$node_name" peer.operations.port)
  node_gossip_node=$(readConfPeerValue "$node_name" peer.gossip.node)
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

  cp -r "$DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH" "$node_home/$CHAINCODE_EXTERNAL_BUILDER_PATH"
  cp -r "$org_home/crypto-config/peerOrganizations/$org_domain/peers/$node_domain/"* "$node_home"

  gossip_node_port=$(readConfPeerValue $node_gossip_node peer.port)
  core_file=$node_home/core.yaml
  sed -e "s/<peer.name>/${node_name}/
  s/<peer.mspid>/${org_mspid}/
  s/<peer.address>/${node_domain}:${node_port}/
  s/<peer.domain>/${node_domain}/
  s/<peer.gossip.address>/${node_gossip_node}.${org_domain}:${gossip_node_port}/
  s/<peer.operations.port>/${node_operations_port}/
  s/<peer.couchdb.address>/${node_couchdb_address}/
  s/<peer.couchdb.username>/${node_couchdb_user}/
  s/<peer.couchdb.password>/${node_couchdb_pwd}/
  s/<peer.chaincode.builder.path>/${CHAINCODE_EXTERNAL_BUILDER_PATH}/
  s/<peer.chaincode.builder.name>/${CHAINCODE_EXTERNAL_BUILDER_NAME}/
  s/<peer.chaincode.address>/${node_domain}:${node_chaincode_port}/" $CORE_TEMPLATE_FILE > $core_file
  logSuccess "Node config file generated" "$core_file"

  supervisor_process_name=fabric-$org_name-$node_name
  supervisor_conf_file_name=$supervisor_process_name.ini
  supervisor_conf_file=$node_home/$supervisor_conf_file_name
  echo "[program:$supervisor_process_name]" > "$supervisor_conf_file"
  echo "command=$COMMAND_PEER node start" >> "$supervisor_conf_file"
  echo "directory=${node_home}" >> "$supervisor_conf_file"
  echo "redirect_stderr=true" >> "$supervisor_conf_file"
  echo "stdout_logfile=${node_home}/peer.log" >> "$supervisor_conf_file"
  echo "stdout_logfile_maxbytes=20MB" >> "$supervisor_conf_file"
  echo "stdout_logfile_backups=2" >> "$supervisor_conf_file"
  logSuccess "Supervisor config file generate:" "$supervisor_conf_file"

  boot_script_file=$node_home/boot.sh
  echo '#!/bin/bash' > "$boot_script_file"
  echo 'export FABRIC_CFG_PATH=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)' >> "$boot_script_file"
  echo 'if [ -f /usr/local/etc/supervisor.d/'$supervisor_conf_file_name' ]; then' >> "$boot_script_file"
  echo '  rm /usr/local/etc/supervisor.d/'$supervisor_conf_file_name'' >> "$boot_script_file"
  echo 'fi' >> "$boot_script_file"
  echo 'ln '"$supervisor_conf_file"' /usr/local/etc/supervisor.d/' >> "$boot_script_file"
  echo 'supervisorctl update' >> "$boot_script_file"
  echo 'echo Staring: '"$node_name"'' >> "$boot_script_file"
  echo 'sleep 1' >> "$boot_script_file"
  echo 'supervisorctl status' >> "$boot_script_file"
  chmod u+x "$boot_script_file"
  logSuccess "Node boot script generated: " "$boot_script_file"

  stop_script_file=$node_home/stop.sh
  echo '#!/bin/bash' > "$stop_script_file"
  echo 'supervisorctl stop '"$supervisor_process_name" >> "$stop_script_file"
  echo 'rm /usr/local/etc/supervisor.d/'"$supervisor_conf_file_name" >> "$stop_script_file"
  echo 'supervisorctl remove '"$supervisor_process_name" >> "$stop_script_file"
  logSuccess "Node stop script generated: " "$stop_script_file"

  logSuccess "Node config success:" "$node_name"
}

function config {
  org_name=$(readConfOrgValue 'org.name')
  org_mspid=$(readConfOrgValue 'org.mspid')
  org_domain=$(readConfOrgValue 'org.domain')
  org_node_count=$(readConfOrgValue 'org.node.count')
  org_user_count=$(readConfOrgValue 'org.user.count')
  org_anchor_peer=$(readConfOrgValue 'org.anchor.peer')

  logInfo "Start config orgnaization: " "$org_name"
  logInfo "Orgnaization mspid:" "$org_mspid"
  logInfo "Orgnaization domain:" "$org_domain"
  logInfo "Orgnaization node count:" "$org_node_count"
  logInfo "Orgnaization user count:" "$org_user_count"
  logInfo "Orgnaization anchor peer:" "$org_anchor_peer"

  org_home=$WORK_HOME/$org_name
  if [ -d "$org_home" ]; then
      rm -fr "$org_home"
  fi
  mkdir -p "$org_home" && cd "$org_home"
  logInfo "Orgnaization work home:" "$org_home"

  cp "$CONF_FILE" "$org_home/conf.ini"
  # generate org msp config files.
  "$DIR/msp.sh" -t peer -d "$org_home" -f "$CONF_FILE"
  if [ $? != 0 ]; then
      exit 1
  fi

  org_msp_dir=$org_home/crypto-config/peerOrganizations/$org_domain/msp
  org_anchor_peeer_host=$org_anchor_peer.$org_domain
  org_anchor_peeer_port=$(readConfPeerValue $org_anchor_peer peer.port)
  configtx_file=$org_home/configtx-org.yaml
  sed -e "s/<org.name>/${org_name}/
  s/<org.mspid>/${org_mspid}/
  s/<org.mspid>/${org_mspid}/
  s/<org.mspid>/${org_mspid}/
  s:<org.msp.dir>:${org_msp_dir}:
  s/<org.anchor.host>/${org_anchor_peeer_host}/
  s/<org.anchor.port>/${org_anchor_peeer_port}/" "$ORG_CONFIGTX_TEMPLATE_FILE" > "$configtx_file"
  logSuccess "Orgnaization configtx config file generated:" "$configtx_file"

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
      echo "confdir: $CONF_DIR"
      checkdirexist "$CONF_DIR"
      ;;
    *) usage; exit 1;;
  esac
done 

case $COMMAND in 
  configorg)
    checkfileexist "$CRYPTO_CONFIG_TEMPLATE_FILE"
    checkfileexist "$ORG_CONFIGTX_TEMPLATE_FILE"
    checkfileexist "$CORE_TEMPLATE_FILE"
    checkdirexist "$DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH"
    checkfileexist "$COMMAND_CRYPTOGEN"
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
        logSuccess "Node stoped:" "$node_name"
      fi
    done
    logSuccess "Organization all node stoped:" $(pwd)
    ;;
  stopnode)
    if [ "$CONF_DIR" ]; then
      cd "$CONF_DIR"
    fi
    if [ -f stop.sh ]; then
      sh stop.sh
      if [ $? -eq 0 ]; then
        logSuccess "Node stoped:" $(pwd)
      fi
    fi
    ;;
esac 

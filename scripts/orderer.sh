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

TMP_CONF_TX_ORDERER="$DIR/template/configtx-orderer.yaml"
TMP_CONF_TX_COMMON="$DIR/template/configtx-common.yaml"
TMP_ORDERER="$DIR/template/orderer.yaml"

CMD_CRYPTOGEN="$FABRIC_BIN/cryptogen"
CMD_CONFIGTXGEN="$FABRIC_BIN/configtxgen"
CMD_ORDERER="$FABRIC_BIN/orderer"

. $DIR/utils/log-utils.sh
. $DIR/utils/conf-utils.sh
. $DIR/utils/file-utils.sh

function readConfOrgValue() {
  echo $(readConfValue "$CONF_FILE" org "$1")
}

function readConfNodeValue() {
  echo $(readConfValue $CONF_FILE $1 $2)
}

function configNode {
  node_name=$1
  org_name=$2
  org_domain=$3
  org_mspid=$4
  logInfo "Start config node:" "$node_name"
  node_port=$(readConfNodeValue "$node_name" node.port)
  node_operations_port=$(readConfNodeValue "$node_name" node.operations.port)
  logInfo "Node port:" "$node_port"
  logInfo "Node operation port:" "$node_operations_port"

  org_home="$WORK_HOME/$org_name"
  node_home="$org_home/$node_name"
  if [ -d "$node_home" ]; then
      rm -fr "$node_home"
  fi
  mkdir -p "$node_home" && cd "$node_home"
  logInfo "Node work home created:" "$node_home"

  cp -r "$org_home/crypto-config/ordererOrganizations/$org_domain/orderers/$node_name.$org_domain/"* "$node_home"
  logInfo "Node msp directory:" "$node_home/msp"
  logInfo "Node tls directory:" "$node_home/tls"

  node_domain="$node_name.$org_domain"
  orderer_config_file="$node_home/orderer.yaml"
  sed -e "s/<orderer.address>/${node_domain}/
  s/<orderer.port>/${node_port}/
  s/<org.mspid>/${org_mspid}/
  s/<orderer.operations.port>/${node_operations_port}/" "$TMP_ORDERER" > "$orderer_config_file"
  logInfo "Node config file generated:" "$orderer_config_file"

  supervisor_process_name="fabric-$org_name-$node_name"
  supervisor_conf_file_name="$supervisor_process_name.ini"
  supervisor_conf_file="$node_home/$supervisor_conf_file_name"
  echo "[program:$supervisor_process_name]" > "$supervisor_conf_file"
  echo "command=$CMD_ORDERER" >> "$supervisor_conf_file"
  echo "directory=${node_home}" >> "$supervisor_conf_file"
  echo "redirect_stderr=true" >> "$supervisor_conf_file"
  echo "stdout_logfile=${node_home}/orderer.log" >> "$supervisor_conf_file"
  echo "stdout_logfile_maxbytes=20MB" >> "$supervisor_conf_file"
  echo "stdout_logfile_backups=2 " >> "$supervisor_conf_file"
  logInfo "Supervisor config file generated:" "$supervisor_conf_file"

  boot_script_file="$node_home/boot.sh"
  echo '#!/bin/bash' > "$boot_script_file"
  echo 'export FABRIC_CFG_PATH=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)' >> "$boot_script_file"
  echo 'if [ -f /usr/local/etc/supervisor.d/'"$supervisor_conf_file_name"' ]; then' >> "$boot_script_file"
  echo '  rm /usr/local/etc/supervisor.d/'"$supervisor_conf_file_name"'' >> "$boot_script_file"
  echo 'fi' >> "$boot_script_file"
  echo 'ln '"$supervisor_conf_file"' /usr/local/etc/supervisor.d/' >> "$boot_script_file"
  echo 'supervisorctl update' >> "$boot_script_file"
  echo 'echo Starting node: '"$node_name"'' >> "$boot_script_file"
  echo 'supervisorctl status' >> "$boot_script_file"
  chmod u+x "$boot_script_file"
  logInfo "Boot script generated: " "$boot_script_file"

  stop_script_file="$node_home/stop.sh"
  echo '#!/bin/bash' > "$stop_script_file"
  echo 'supervisorctl stop '"$supervisor_process_name" >> "$stop_script_file"
  echo 'rm /usr/local/etc/supervisor.d/'"$supervisor_conf_file_name" >> "$stop_script_file"
  echo 'supervisorctl remove '"$supervisor_process_name" >> "$stop_script_file"
  logInfo "Stop script generatd: " "$boot_script_file"
  logSuccess "Node config success:" "$node_name"
}

function config {
  org_name=$(readConfOrgValue org.name)
  org_mspid=$(readConfOrgValue org.mspid)
  org_domain=$(readConfOrgValue org.domain)
  org_node_count=$(readConfOrgValue org.node.count)
  logInfo "Start config orderer organization:" "$org_name"
  logInfo "Organization name:" "$org_name"
  logInfo "Organization mspid:" "$org_mspid"
  logInfo "Organization domain:" "$org_domain"
  logInfo "Organization node count:" "$org_node_count"

  org_home="$WORK_HOME/$org_name"
  if [ -d "$org_home" ]; then
    rm -fr "$org_home"
  fi
  mkdir -p "$org_home" && cd "$org_home"
  logInfo "Organization work dir:" "$org_home"
  cp "$CONF_FILE" "$org_home/conf.ini"
  # generate msp config files.
  "$DIR/msp.sh" -t orderer -d "$org_home" -f "$CONF_FILE"
  if [ $? != 0 ]; then
      exit 1
  fi

  org_msp_dir="$org_home/crypto-config/ordererOrganizations/$org_domain/msp"
  org_configtx_file="$org_home/configtx-org.yaml"
  sed -e "s/<org.name>/${org_name}/
  s/<org.mspid>/${org_mspid}/
  s:<org.msp.dir>:${org_msp_dir}:" "$TMP_CONF_TX_ORDERER" > "$org_configtx_file"
  logSuccess "Organization configtx file generated:" "$org_configtx_file"

  # config system channel genesis block
  genesis_configtx_file="$org_home/configtx.yaml"
  echo "Organizations:" > "$genesis_configtx_file"
  cat $org_configtx_file >> "$genesis_configtx_file"
  _peerorgs=$(readConfNodeValue genesis genesis.peerorg.list)
  peerorgs=(${_peerorgs//,/ })
  for peer_org_name in ${peerorgs[@]}
  do
    cat "$WORK_HOME/$peer_org_name/configtx-org.yaml" >> "$genesis_configtx_file"
  done
  cat "$TMP_CONF_TX_COMMON" >> "$genesis_configtx_file"
  for (( i = 0; i < "$org_node_count" ; ++i)); do
    node_name=orderer${i}
    node_home="$org_home/$node_name"
    node_address="$node_name.$org_domain"
    node_port=$(readConfNodeValue "$node_name" node.port)
    echo '            - Host: '"${node_address}"'
              Port: '"${node_port}"'
              ClientTLSCert: '"${node_home}"'/tls/server.crt
              ServerTLSCert: '"${node_home}"'/tls/server.crt' >> "$genesis_configtx_file"
  done
  echo 'Profiles:
  SampleMultiNodeEtcdRaft:
      <<: *ChannelDefaults
      Capabilities:
          <<: *ChannelCapabilities
      Orderer:
          <<: *OrdererDefaults
          Organizations:
          - *'"${org_name}"'
          Capabilities:
              <<: *OrdererCapabilities
      Application:
          <<: *ApplicationDefaults
          Organizations:
          - <<: *'"${org_name}"'
      Consortiums:
          SampleConsortium:
              Organizations:' >> "$genesis_configtx_file"
  for peer_org_name in ${peerorgs[@]}
  do
    echo "                - *${peer_org_name}" >> "$genesis_configtx_file"
  done
  logInfo "Configtx file generated::" "$genesis_configtx_file"

  for (( i = 0; i < "$org_node_count" ; ++i)); do
    configNode "orderer$i" "$org_name" "$org_domain" "$org_mspid"
  done

  sys_channel_name=$(readConfOrgValue org.sys.channel.name)
  logInfo "System channel name:" "$sys_channel_name"
  sys_channel_genesis_file="$org_home/genesis.block"

  $CMD_CONFIGTXGEN \
    -profile SampleMultiNodeEtcdRaft \
    -channelID "$sys_channel_name" \
    -outputBlock "$sys_channel_genesis_file" \
    -configPath "$org_home"
  logInfo "System channel genesis block file generated:" "$sys_channel_genesis_file"

  for (( i = 0; i < "$org_node_count" ; ++i)); do
    cp "$org_home/genesis.block" "$org_home/orderer$i/"
  done
  logSuccess "Organization config success:" "$org_name"
}


function usage {
    echo "USAGE:"
    echo "  orderer.sh <command> [ -f configfile | -o orgName ]"
    echo "      command: [ configorg | startorg | stoporg | startnode | stropnode | usage ]"
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
      checkfileexist "$CONF_FILE";;
    d) CONF_DIR=$(absolutefile "$OPTARG" "$WORK_HOME")
      checkdirexist "$CONF_DIR";;
    *) usage; exit 1;;
  esac
done

case "$COMMAND" in
  configorg)
    checkfileexist "$CONF_FILE"
    checkfileexist "$TMP_CONF_TX_ORDERER"
    checkfileexist "$TMP_CONF_TX_COMMON"
    checkfileexist "$TMP_ORDERER"
    checkfileexist "$CMD_CRYPTOGEN"
    checkfileexist "$CMD_CONFIGTXGEN"
    checkfileexist "$CMD_ORDERER"
    config
    ;;
  startorg)
    if [ "$CONF_DIR" ]; then
        cd "$CONF_DIR"
    fi
    for node_name in $(ls . | grep orderer); do
        sh "$node_name"/boot.sh
        if [ $? -eq 0 ]; then
            logSuccess "Node started:" "$node_name"
        fi
    done
    sleep 3
    logSuccess "Orgnaization all node started:" $(pwd);;
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
    fi;;
  stoporg)
    if [ "$CONF_DIR" ]; then
      cd "$CONF_DIR"
    fi
    for node_name in $(ls . | grep orderer); do
      sh "$node_name"/stop.sh
      if [ $? -eq 0 ]; then
        logSuccess "Node stoped:" "$node_name"
      fi
    done
    logSuccess "Orgnaization all node stoped:" $(pwd);;
  stopnode)
    if [ "$CONF_DIR" ]; then
      cd "$CONF_DIR"
    fi
    if [ -f stop.sh ]; then
      sh stop.sh
      if [ $? -eq 0 ]; then
        logSuccess "Node stoped:" $(pwd)
      fi
    fi;;
  *) usage; exit 1;;
esac
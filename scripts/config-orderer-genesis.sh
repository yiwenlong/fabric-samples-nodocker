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

SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
HOME=$(pwd)

# shellcheck source=utils/log-utils.sh
. "$SCRIPT_DIR/utils/log-utils.sh"
# shellcheck source=utils/file-utils.sh
. "$SCRIPT_DIR/utils/file-utils.sh"
# shellcheck source=utils/conf-utils.sh
. "$SCRIPT_DIR/utils/conf-utils.sh"

TMP_CONF_TX_COMMON="$SCRIPT_DIR/template/configtx-common.yaml"
TMP_CONF_TX_COMMON_PROFILES="$SCRIPT_DIR/template/configtx-common-profiles.yaml"
CMD_CONFIGTXGEN="$FABRIC_BIN/configtxgen"

while getopts f: opt
do
  case $opt in
    f) conf_file=$OPTARG ;;
    *) usage; exit 1;;
  esac
done

checkfileexist "$conf_file"

org_name=$(readConfValue "$conf_file" org org.name)
org_node_count=$(readConfValue "$conf_file" org org.node.count)

org_home="$HOME/$org_name"
checkdirexist "$org_home"

orderer_org_snippet="$org_home/configtx-org.yaml"
checkfileexist "$orderer_org_snippet"

orgs=$(readConfValue "$conf_file" genesis genesis.peerorg.list)

genesis_configtx_file="$org_home/configtx.yaml"
echo "Organizations:" > "$genesis_configtx_file"
cat "$orderer_org_snippet" >> "$genesis_configtx_file"
for org in ${orgs//,/ }; do
  org_snippet="$HOME/$org/configtx-org.yaml"
  checkfileexist "$org_snippet"
  cat "$org_snippet" >> "$genesis_configtx_file"
done

cat "$TMP_CONF_TX_COMMON" >> "$genesis_configtx_file"
for (( i = 0; i < "$org_node_count" ; ++i)); do
  node_name=orderer${i}
  node_address=$(readConfValue "$conf_file" "$node_name" node.access.address)
  node_port=$(readConfValue "$conf_file" "$node_name" node.access.port)
  printf "        - %s:%s\n" "$node_address" "$node_port" >> "$genesis_configtx_file"
done

sed -e "s/_org_name_/${org_name}/" "$TMP_CONF_TX_COMMON_PROFILES" >> "$genesis_configtx_file"
for (( i = 0; i < "$org_node_count" ; ++i)); do
  node_name=orderer${i}
  node_home="$org_home/$node_name"
  node_address=$(readConfValue "$conf_file" "$node_name" node.access.address)
  node_port=$(readConfValue "$conf_file" "$node_name" node.access.port)
  printf "          - Host: %s\n" "$node_address" >> "$genesis_configtx_file"
  printf "            Port: %s\n" "$node_port" >> "$genesis_configtx_file"
  printf "            ClientTLSCert: %s\n" "$node_home/tls/server.crt" >> "$genesis_configtx_file"
  printf "            ServerTLSCert: %s\n" "$node_home/tls/server.crt" >> "$genesis_configtx_file"
done
echo "      Addresses:" >> "$genesis_configtx_file"
for (( i = 0; i < "$org_node_count" ; ++i)); do
  node_name=orderer${i}
  node_address=$(readConfValue "$conf_file" "$node_name" node.access.address)
  node_port=$(readConfValue "$conf_file" "$node_name" node.access.port)
  printf "          - %s:%s\n" "$node_address" "$node_port" >> "$genesis_configtx_file"
done
printf "      Organizations:\n" >> "$genesis_configtx_file"
printf "      - *%s\n" "$org_name" >> "$genesis_configtx_file"
printf "      Capabilities:\n" >> "$genesis_configtx_file"
printf "        <<: *OrdererCapabilities\n" >> "$genesis_configtx_file"
printf "    Application:\n" >> "$genesis_configtx_file"
printf "      <<: *ApplicationDefaults\n" >> "$genesis_configtx_file"
printf "      Organizations:\n" >> "$genesis_configtx_file"
printf "      - <<: *%s\n" "$org_name" >> "$genesis_configtx_file"
printf "    Consortiums:\n" >> "$genesis_configtx_file"
printf "      SampleConsortium:\n" >> "$genesis_configtx_file"
printf "        Organizations:\n" >> "$genesis_configtx_file"

for org in ${orgs//,/ }; do
  printf "        - *%s\n" "$org" >> "$genesis_configtx_file"
done
logInfo "Configtx file generated:" "$genesis_configtx_file"

sys_channel_name=$(readConfValue "$conf_file" org org.sys.channel.name)
logInfo "System channel name:" "$sys_channel_name"
sys_channel_genesis_file="$org_home/genesis.block"
$CMD_CONFIGTXGEN \
  -profile SampleMultiNodeEtcdRaft \
  -channelID "$sys_channel_name" \
  -outputBlock "$sys_channel_genesis_file" \
  -configPath "$org_home"
logInfo "System channel genesis block file generated:" "$sys_channel_genesis_file"
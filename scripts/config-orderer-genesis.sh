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

CMD_CONFIGTXGEN="$FABRIC_BIN/configtxgen"

while getopts f: opt
do
  case $opt in
    f) conf_file=$OPTARG ;;
    *) usage; exit 1;;
  esac
done

checkfileexist "$conf_file"
org_conf_files=$(readConfValue "$conf_file" "genesis" "genesis.org.conf.files")
for org_conf_file in $org_conf_files; do
  checkfileexist "$org_conf_file"
done

orderer_org_name=$(readConfValue "$conf_file" org org.name)
orderer_org_msp_id=$(readConfValue "$conf_file" org org.mspid)
orderer_org_msp_dir=$(readConfValue "$conf_file" org org.crypto.dir)
orderer_org_domain=$(readConfValue "$conf_file" org org.domain)
orderer_crypto_dir=$HOME/$orderer_org_msp_dir/ordererOrganizations/$orderer_org_domain

orderer_org_home="$HOME/$orderer_org_name"
if [ ! -d "$orderer_org_home" ]; then
  mkdir -p "$orderer_org_name"
fi

genesis_configtx_file="$orderer_org_home/configtx.yaml"

cat << EOF > "$genesis_configtx_file"
Organizations:
  - &$orderer_org_name
    Name: $orderer_org_name
    ID: $orderer_org_msp_id
    MSPDir: $orderer_crypto_dir/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('$orderer_org_msp_id.member')"
      Writers:
        Type: Signature
        Rule: "OR('$orderer_org_msp_id.member')"
      Admins:
        Type: Signature
        Rule: "OR('$orderer_org_msp_id.admin')"
EOF

for org_conf_file in $org_conf_files; do
  org_name=$(readConfValue "$org_conf_file" org org.name)
  org_msp_id=$(readConfValue "$org_conf_file" org org.mspid)
  org_msp_dir=$(readConfValue "$org_conf_file" org org.crypto.dir)
  org_domain=$(readConfValue "$org_conf_file" org org.domain)
cat << EOF >> "$genesis_configtx_file"
  - &$org_name
    Name: $org_name
    ID: $org_msp_id
    MSPDir: $HOME/$org_msp_dir/peerOrganizations/$org_domain/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('$org_msp_id.member')"
      Writers:
        Type: Signature
        Rule: "OR('$org_msp_id.admin', '$org_msp_id.client')"
      Admins:
        Type: Signature
        Rule: "OR('$org_msp_id.admin')"
      Endorsement:
        Type: Signature
        Rule: "OR('$org_msp_id.peer')"
EOF
done

cat << EOF >> "$genesis_configtx_file"
Capabilities:
  Channel: &ChannelCapabilities
    V2_0: true
  Orderer: &OrdererCapabilities
    V2_0: true
  Application: &ApplicationCapabilities
    V2_0: true
Application: &ApplicationDefaults
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
    LifecycleEndorsement:
      Type: ImplicitMeta
      Rule: "MAJORITY Endorsement"
    Endorsement:
      Type: ImplicitMeta
      Rule: "MAJORITY Endorsement"
  Capabilities:
    <<: *ApplicationCapabilities
Channel: &ChannelDefaults
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
  Capabilities:
    <<: *ChannelCapabilities
Orderer: &OrdererDefaults
  OrdererType: etcdraft
  BatchTimeout: 2s
  BatchSize:
    MaxMessageCount: 10
    AbsoluteMaxBytes: 99 MB
    PreferredMaxBytes: 512 KB
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
    BlockValidation:
      Type: ImplicitMeta
      Rule: "ANY Writers"
Profiles:
  SampleMultiNodeEtcdRaft:
    <<: *ChannelDefaults
    Capabilities:
      <<: *ChannelCapabilities
    Orderer:
      <<: *OrdererDefaults
      OrdererType: etcdraft
      EtcdRaft:
        Consenters:
EOF

org_node_count=$(readConfValue "$conf_file" org org.node.count)
for (( i = 0; i < "$org_node_count" ; ++i)); do
  node_name=orderer${i}
  node_address=$(readConfValue "$conf_file" "$node_name" node.access.address)
  node_port=$(readConfValue "$conf_file" "$node_name" node.access.port)
cat << EOF >> "$genesis_configtx_file"
          - Host: $node_address
            Port: $node_port
            ClientTLSCert: $orderer_crypto_dir/orderers/$node_name.$orderer_org_domain/tls/server.crt
            ServerTLSCert: $orderer_crypto_dir/orderers/$node_name.$orderer_org_domain/tls/server.crt
EOF
done

cat << EOF >> "$genesis_configtx_file"
      Addresses:
EOF

org_node_count=$(readConfValue "$conf_file" org org.node.count)
for (( i = 0; i < "$org_node_count" ; ++i)); do
  node_address=$(readConfValue "$conf_file" "orderer${i}" node.access.address)
  node_port=$(readConfValue "$conf_file" "orderer${i}" node.access.port)
cat << EOF >> "$genesis_configtx_file"
        - $node_address:$node_port
EOF
done

cat << EOF >> "$genesis_configtx_file"
      Organizations:
        - *$orderer_org_name
      Capabilities:
        <<: *OrdererCapabilities
    Application:
      <<: *ApplicationDefaults
      Organizations:
      - <<: *$orderer_org_name
    Consortiums:
      SampleConsortium:
        Organizations:
EOF

for org_conf_file in $org_conf_files; do
  org_name=$(readConfValue "$org_conf_file" org org.name)
cat << EOF >> "$genesis_configtx_file"
          - *$org_name
EOF
done

logInfo "Configtx file generated:" "$genesis_configtx_file"

sys_channel_name=$(readConfValue "$conf_file" org org.sys.channel.name)
logInfo "System channel name:" "$sys_channel_name"
sys_channel_genesis_file="$orderer_org_home/genesis.block"
$CMD_CONFIGTXGEN \
  -profile SampleMultiNodeEtcdRaft \
  -channelID "$sys_channel_name" \
  -outputBlock "$sys_channel_genesis_file" \
  -configPath "$orderer_org_home"
logInfo "System channel genesis block file generated:" "$sys_channel_genesis_file"
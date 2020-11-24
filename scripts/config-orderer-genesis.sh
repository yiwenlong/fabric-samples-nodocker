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

while getopts f:d: opt
do
  case $opt in
    f) conf_file=$OPTARG ;;
    d) dst_path=$OPTARG ;;
    *) usage; exit 1;;
  esac
done

checkfileexist "$conf_file"
checkdirexist "$dst_path"

# Read orderer org config files.
orderer_org_conf_files=$(readConfValue "$conf_file" "genesis" "orderer.org.conf.files")
for org_conf_file in $orderer_org_conf_files; do
  checkfileexist "$org_conf_file"
done

# Read peer org config files.
peer_org_conf_files=$(readConfValue "$conf_file" "genesis" "peer.org.conf.files")
for org_conf_file in $peer_org_conf_files; do
  checkfileexist "$org_conf_file"
done

genesis_configtx_file="$dst_path/configtx.yaml"

echo "Organizations:" > "$genesis_configtx_file"

for org_conf_file in $orderer_org_conf_files; do
  orderer_org_name=$(readConfValue "$org_conf_file" org org.name)
  orderer_org_msp_id=$(readConfValue "$org_conf_file" org org.mspid)
  orderer_org_msp_dir=$(readConfValue "$org_conf_file" org org.crypto.dir)
  orderer_org_domain=$(readConfValue "$org_conf_file" org org.domain)
  orderer_crypto_dir=$HOME/$orderer_org_msp_dir/ordererOrganizations/$orderer_org_domain
cat << EOF >> "$genesis_configtx_file"
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
done

for org_conf_file in $peer_org_conf_files; do
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
    V1_4_3: true
    V1_3: false
    V1_1: false
  Orderer: &OrdererCapabilities
    V1_4_2: true
    V1_1: false
  Application: &ApplicationCapabilities
    V1_4_2: true
    V1_3: false
    V1_2: false
    V1_1: false
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
  EtcdRaft:
    Consenters:
EOF

for org_conf_file in $orderer_org_conf_files; do
  orderer_org_msp_dir=$(readConfValue "$org_conf_file" org org.crypto.dir)
  orderer_org_domain=$(readConfValue "$org_conf_file" org org.domain)
  orderer_crypto_dir=$HOME/$orderer_org_msp_dir/ordererOrganizations/$orderer_org_domain

  org_node_count=$(readConfValue "$org_conf_file" org org.node.count)

  for (( i = 0; i < "$org_node_count" ; ++i)); do
    node_name=orderer${i}
    node_address=$(readConfValue "$org_conf_file" "$node_name" node.access.address)
    node_port=$(readConfValue "$org_conf_file" "$node_name" node.access.port)
cat << EOF >> "$genesis_configtx_file"
          - Host: $node_address
            Port: $node_port
            ClientTLSCert: $orderer_crypto_dir/orderers/$node_name.$orderer_org_domain/tls/server.crt
            ServerTLSCert: $orderer_crypto_dir/orderers/$node_name.$orderer_org_domain/tls/server.crt
EOF
  done
done

cat << EOF >> "$genesis_configtx_file"
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

for org_conf_file in $orderer_org_conf_files; do
  orderer_org_msp_dir=$(readConfValue "$org_conf_file" org org.crypto.dir)
  orderer_org_domain=$(readConfValue "$org_conf_file" org org.domain)
  orderer_crypto_dir=$HOME/$orderer_org_msp_dir/ordererOrganizations/$orderer_org_domain

  org_node_count=$(readConfValue "$org_conf_file" org org.node.count)

  for (( i = 0; i < "$org_node_count" ; ++i)); do
    node_name=orderer${i}
    node_address=$(readConfValue "$org_conf_file" "$node_name" node.access.address)
    node_port=$(readConfValue "$org_conf_file" "$node_name" node.access.port)
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

  for (( i = 0; i < "$org_node_count" ; ++i)); do
    node_address=$(readConfValue "$org_conf_file" "orderer${i}" node.access.address)
    node_port=$(readConfValue "$org_conf_file" "orderer${i}" node.access.port)
cat << EOF >> "$genesis_configtx_file"
        - $node_address:$node_port
EOF
  done
done

cat << EOF >> "$genesis_configtx_file"
      Organizations:
EOF

for org_conf_file in $orderer_org_conf_files; do
  org_name=$(readConfValue "$org_conf_file" org org.name)
cat << EOF >> "$genesis_configtx_file"
        - *$orderer_org_name
EOF
done

cat << EOF >> "$genesis_configtx_file"
      Capabilities:
        <<: *OrdererCapabilities
    Application:
      <<: *ApplicationDefaults
      Organizations:
EOF

for org_conf_file in $orderer_org_conf_files; do
  org_name=$(readConfValue "$org_conf_file" org org.name)
cat << EOF >> "$genesis_configtx_file"
      - <<: *$orderer_org_name
EOF
done

cat << EOF >> "$genesis_configtx_file"
    Consortiums:
      SampleConsortium:
        Organizations:
EOF

for org_conf_file in $peer_org_conf_files; do
  org_name=$(readConfValue "$org_conf_file" org org.name)
cat << EOF >> "$genesis_configtx_file"
          - *$org_name
EOF
done

logInfo "Configtx file generated:" "$genesis_configtx_file"

sys_channel_name=$(readConfValue "$conf_file" "genesis" system.channel.name)
logInfo "System channel name:" "$sys_channel_name"
sys_channel_genesis_file="$dst_path/genesis.block"
$CMD_CONFIGTXGEN \
  -profile SampleMultiNodeEtcdRaft \
  -channelID "$sys_channel_name" \
  -outputBlock "$sys_channel_genesis_file" \
  -configPath "$dst_path"
logInfo "System channel genesis block file generated:" "$sys_channel_genesis_file"
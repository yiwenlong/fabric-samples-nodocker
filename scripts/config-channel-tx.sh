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
WORK_HOME=$(pwd)

CMD_CONFIGTXGEN="$FABRIC_BIN/configtxgen"

# shellcheck source=scripts/utils/conf-utils.sh
. "${SCRIPT_DIR}/utils/conf-utils.sh"
# shellcheck source=utils/log-utils.sh
. "$SCRIPT_DIR/utils/log-utils.sh"
# shellcheck source=utils/file-utils.sh
. "$SCRIPT_DIR/utils/file-utils.sh"

while getopts f: opt
do
  case $opt in
    f) conf_file=$OPTARG ;;
    *) usage; exit 1;;
  esac
done

ch_name=$(readConfValue "$conf_file" "channel" channel.name)
ch_orgs=$(readConfValue "$conf_file" "channel" channel.orgs)
ch_home="$WORK_HOME/$ch_name"
if [ ! -d "$ch_home" ]; then
    mkdir -p "$ch_home"
fi

ch_configtx_file="$ch_home/configtx.yaml"
cat << EOF > "$ch_configtx_file"
Organizations:
EOF
for org_name in $ch_orgs; do
  org_msp_id=$(readConfValue "$conf_file" "$org_name" org.mspid)
  org_msp_dir=$(readConfValue "$conf_file" "$org_name" org.msp.dir)
  org_anchor_host=$(readConfValue "$conf_file" "$org_name" org.anchor.host)
  org_anchor_port=$(readConfValue "$conf_file" "$org_name" org.anchor.port)

  org_msp_absolute_dir=$(absolutefile "$org_msp_dir" "$WORK_HOME")
  if [ ! -d "$org_msp_absolute_dir" ]; then
    logError "Organization msp config dir not found:" "$org_msp_absolute_dir"
    exit 1
  fi
cat << EOF >> "$ch_configtx_file"
  - &$org_name
    Name: $org_name
    ID: $org_msp_id
    MSPDir: $org_msp_absolute_dir
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
    AnchorPeers:
      - Host: $org_anchor_host
        Port: $org_anchor_port
EOF
done

cat << EOF >> "$ch_configtx_file"
Capabilities:
  Channel: &ChannelCapabilities
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
Profiles:
  $ch_name-Profile:
    Consortium: SampleConsortium
    <<: *ChannelDefaults
    Application:
      <<: *ApplicationDefaults
      Capabilities:
        <<: *ApplicationCapabilities
      Organizations:
EOF
for org in $ch_orgs; do
cat << EOF >> "$ch_configtx_file"
        - *$org
EOF
done

ch_tx_file="$ch_home/$ch_name.tx"
if ! $CMD_CONFIGTXGEN \
    -profile "$ch_name-Profile" \
    -outputCreateChannelTx "$ch_tx_file" \
    -channelID "$ch_name" \
    -configPath "$ch_home" ; then
    logError "Transaction Generate Error:" "$ch_tx_file"
    exit $?
fi
logInfo "Create channel transaction file has been generated:" "$ch_tx_file"

for org_name in $ch_orgs; do
  anchor_tx_file="$ch_home/${org_name}-$ch_name-anchor.tx"
    if ! $CMD_CONFIGTXGEN \
        -profile "$ch_name-Profile" \
        -outputAnchorPeersUpdate "$anchor_tx_file" \
        -channelID "$ch_name" \
        -asOrg "$org_name" \
        -configPath "$ch_home"; then
        logError "Transaction Generate Error:" "$anchor_tx_file"
        exit $?
    fi
    logInfo "Anchor peer transaction file for $org_name has been generated:" "$anchor_tx_file"
done
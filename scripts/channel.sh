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

CONFIGTX_COMMON_TEMPLATE_FILE="$DIR/template/configtx-common-channel.yaml"

COMMAND_PEER="$FABRIC_BIN/peer"
COMMAND_CONFIGTXGEN="$FABRIC_BIN/configtxgen"

# shellcheck source=utils/log-utils.sh
. "$DIR/utils/log-utils.sh"
# shellcheck source=utils/conf-utils.sh
. "$DIR/utils/conf-utils.sh"
# shellcheck source=utils/file-utils.sh
. "$DIR/utils/file-utils.sh"

function readValue {
  readConfValue "$CONF_FILE" "$1"; echo
}

function readNodeValue {
  readConfValue "$CONF_FILE" "$1" "$2"; echo
}

#
# Config channel setup files with a conf config file.
# See simpleconfigs/channel.conf for more.
#
# 1. Read params about the channel from config file.
# 2. Generate a directory for the channel to store files.
# 3. Generate configtx.yaml.
# 4. Generate transaction file for create channel.
# 5. Generate transaction files for update anchor peer.
# 6. Generate tool scripts for every peer node.
# 
function config {

  # 1. Read params about the channel from config file.
  ch_name=$(readValue channel.name)
  ch_profile=$(readValue channel.profile)
  ch_orgs=$(readValue channel.orgs)
  ch_orderer=$(readValue channel.orderer)
  logInfo "Start config channel:" "$ch_name"
  logInfo "Channel profile name:" "$ch_profile"
  logInfo "Channel organizations:" "$ch_orgs"

    # 2. Generate a directory for the channel to store files.
    ch_home="$WORK_HOME/$ch_name"
    if [ -d "$ch_home" ]; then
        rm -fr "$ch_home"
    fi 
    mkdir -p "$ch_home" && cd "$ch_home" || exit
    logInfo "Channel Home dir:" "$ch_home"

    # 3. Generate configtx.yaml.
    ch_configtx_file="$ch_home/configtx.yaml"
    echo "Organizations:" > "$ch_configtx_file"
    for org_name in $ch_orgs; do
        org_ch_configtx_file="$WORK_HOME/$(readNodeValue "$org_name" 'org.configtx')"
        checkfileexist "$org_ch_configtx_file"
        cat "$org_ch_configtx_file" >> "$ch_configtx_file"
    done 
    # 3.2. Wirte common code. 
    cat "$CONFIGTX_COMMON_TEMPLATE_FILE" >> "$ch_configtx_file"
    # 3.3. Write channel profile
    for org_name in $ch_orgs; do
        echo "                - *${org_name}" >> "$ch_configtx_file"
    done 
    echo '            Capabilities:
                <<: *ApplicationCapabilities' >> "$ch_configtx_file"
    logInfo "Channel tx config file has been generated:" "$ch_configtx_file"

    # 4. Generate transaction file for create channel.
    ch_tx_file="$ch_home/$ch_name.tx"
    if ! $COMMAND_CONFIGTXGEN \
        -profile "$ch_profile" \
        -outputCreateChannelTx "$ch_tx_file" \
        -channelID "$ch_name" \
        -configPath "$ch_home" ; then
        logError "Transaction Generate Error:" "$ch_tx_file"
        exit $?
    fi
    logInfo "Channel transaction file has been generated:" "$ch_tx_file"
    
    # 5. Generate transaction files for update anchor peer.
    for org_name in $ch_orgs; do
        anchor_tx_file="$ch_home/${org_name}Panchors.tx"
        if ! $COMMAND_CONFIGTXGEN \
            -profile "$ch_profile" \
            -outputAnchorPeersUpdate "$anchor_tx_file" \
            -channelID "$ch_name" \
            -asOrg "$org_name" \
            -configPath "$ch_home"; then
            logError "Transaction Generate Error:" "$anchor_tx_file"
            exit $?
        fi
        logInfo "Anchor peer transaction file for $org_name has been generated:" "$anchor_tx_file"
    done 

    # 6. Generate tool scripts for every peer node.
    orderer_tls_ca_file=$WORK_HOME/$(readNodeValue "$ch_orderer" org.tls.ca)
    orderer_address=$(readNodeValue "$ch_orderer" org.address)
    checkfileexist "$orderer_tls_ca_file"

    for org_name in $ch_orgs; do
        org_node_list=$(readNodeValue "$org_name" 'org.node.list')
        org_admin_msp_dir=$WORK_HOME/$(readNodeValue "$org_name" 'org.admin.msp.dir')
        org_msp_id=$(readNodeValue "$org_name" 'org.mspid')
        org_tls_ca_file=$WORK_HOME/$(readNodeValue "$org_name" 'org.tls.ca')
        checkdirexist "$org_admin_msp_dir"
        checkfileexist "$org_tls_ca_file"

        for node_name in $org_node_list; do
            ch_node_conf_home="$ch_home/$org_name-$node_name-$ch_name-conf"
            mkdir -p "$ch_node_conf_home"
            ch_node_conf_file="$ch_node_conf_home/channel.ini"
            cp "$org_tls_ca_file" "$ch_node_conf_home/peer-tls-ca.pem"
            cp "$orderer_tls_ca_file" "$ch_node_conf_home/orderer-tls-ca.pem"
            cp "$ch_home/$ch_name.tx" "$ch_node_conf_home"
            cp "$ch_home/${org_name}Panchors.tx" "$ch_node_conf_home"
            cp -r "$org_admin_msp_dir" "$ch_node_conf_home/adminmsp"

            node_address=$(readNodeValue "$org_name.$node_name" 'node.address')

            echo "channel.name=$ch_name" > "$ch_node_conf_file"
            echo "channel.create.tx.file.name=$ch_name.tx" >> "$ch_node_conf_file"
            echo "orderer.address=$orderer_address" >> "$ch_node_conf_file"
            echo "orderer.tls.ca=orderer-tls-ca.pem" >> "$ch_node_conf_file"
            echo "org.anchorfile=${org_name}Panchors.tx" >> "$ch_node_conf_file"
            echo "org.name=$org_name" >> "$ch_node_conf_file"
            echo "org.mspid=$org_msp_id" >> "$ch_node_conf_file"
            echo "org.adminmsp=adminmsp" >> "$ch_node_conf_file"
            echo "org.peer.address=$node_address" >> "$ch_node_conf_file"
            echo "org.tls.ca=peer-tls-ca.pem" >> "$ch_node_conf_file"

            logSuccess "Channel config home for org: $org_name node: $node_name has been generated:" "$ch_node_conf_home"
        done 
    done 

    logSuccess "Channel config success:" "$ch_name"
}

function create {

    tx_file=$CONF_DIR/$(readValue "channel.create.tx.file.name")
    orderer_tls_file=$CONF_DIR/$(readValue "orderer.tls.ca")
    org_tls_file=$CONF_DIR/$(readValue "org.tls.ca")
    admin_msp_dir=$CONF_DIR/$(readValue "org.adminmsp")

    peer_address=$(readValue "org.peer.address")
    orderer_address=$(readValue "orderer.address")
    org_mspid=$(readValue "org.mspid")
    ch_name=$(readValue "channel.name")

    checkfileexist "$tx_file"
    checkfileexist "$orderer_tls_file"
    checkfileexist "$org_tls_file"
    checkdirexist "$admin_msp_dir"

    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH=$admin_msp_dir
    export CORE_PEER_LOCALMSPID=$org_mspid
    export CORE_PEER_ADDRESS=$peer_address
    export CORE_PEER_TLS_ROOTCERT_FILE=$org_tls_file

    block_file=$CONF_DIR/$ch_name.block

    $COMMAND_PEER channel create \
        -c "$ch_name" -f "$tx_file" \
        -o "$orderer_address" --tls --cafile "$orderer_tls_file" \
        --outputBlock "$block_file"
}

function join {
    admin_msp_dir=$CONF_DIR/$(readValue "org.adminmsp")
    org_mspid=$(readValue "org.mspid")
    peer_address=$(readValue "org.peer.address")
    org_tls_file=$CONF_DIR/$(readValue "org.tls.ca")
    ch_name=$(readValue "channel.name")
    logInfo "Join channel:" "$ch_name"
    logInfo "Organization admin msp directory:" "$admin_msp_dir"
    logInfo "Organization mspid:" "$org_mspid"
    logInfo "Organization node address:" "$peer_address"
    logInfo "Organization TLS ca file:" "$org_tls_file"
    checkdirexist "$admin_msp_dir"
    checkfileexist "$org_tls_file"

    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH="$admin_msp_dir"
    export CORE_PEER_LOCALMSPID="$org_mspid"
    export CORE_PEER_ADDRESS="$peer_address"
    export CORE_PEER_TLS_ROOTCERT_FILE="$org_tls_file"

    block_file="$CONF_DIR/$ch_name.block"

    orderer_address=$(readValue "orderer.address")
    orderer_tls_file=$CONF_DIR/$(readValue "orderer.tls.ca")
    logInfo "Orderer address:" "$orderer_address"
    logInfo "Orderer TLS ca file:" "$orderer_tls_file"
    checkfileexist "$orderer_tls_file"

    if [ ! -f "$block_file" ]; then
        $COMMAND_PEER channel fetch oldest "$block_file" \
            -o "$orderer_address" \
            -c "$ch_name" \
            --tls --cafile "$orderer_tls_file"
    fi

    if ! $COMMAND_PEER channel join \
        -b "$block_file" \
        -o "$orderer_address" --tls --cafile "$orderer_tls_file"; then
      logError "Join channel failed:" "$peer_address -> $ch_name"
      exit 1
    fi

    logSuccess "Join channel success:" "$peer_address -> $ch_name"
    $COMMAND_PEER channel list
}

function updateAnchorPeer {

    admin_msp_dir=$CONF_DIR/$(readValue "org.adminmsp")
    org_mspid=$(readValue "org.mspid")
    peer_address=$(readValue "org.peer.address")
    org_tls_file=$CONF_DIR/$(readValue "org.tls.ca")

    ch_name=$(readValue "channel.name")

    checkdirexist "$admin_msp_dir"
    checkfileexist "$org_tls_file"

    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH=$admin_msp_dir
    export CORE_PEER_LOCALMSPID=$org_mspid
    export CORE_PEER_ADDRESS=$peer_address
    export CORE_PEER_TLS_ROOTCERT_FILE=$org_tls_file

    orderer_address=$(readValue "orderer.address")
    orderer_tls_file=$CONF_DIR/$(readValue "orderer.tls.ca")
    anchor_tx_file=$CONF_DIR/$(readValue "org.anchorfile")

    checkfileexist "$orderer_tls_file"

    checkfileexist "$anchor_tx_file"

    $COMMAND_PEER channel update \
        -c "$ch_name" -f "$anchor_tx_file" \
        -o "$orderer_address" --tls --cafile "$orderer_tls_file"
}

function usage {
    echo "USAGE:"
    echo "  channel.sh <commadn> -f configfile"
    echo "      command: [ config | create | join | updateAnchorPeer | usage ]"
}

COMMAND=$1
if [ ! "$COMMAND" ]; then
    usage
    exit 1
fi 
shift

while getopts f:d: opt
do 
    case $opt in 
        f) CONF_FILE=$(absolutefile "$OPTARG" "$WORK_HOME");;
        d) CONF_DIR=$(absolutefile "$OPTARG" "$WORK_HOME");;
        *) usage; exit 1;;
    esac 
done

case $COMMAND in 
  config)
    checkfileexist "$CONF_FILE"
    config ;;
  create | join | updateAnchorPeer )
    checkdirexist "$CONF_DIR"
    CONF_FILE="$CONF_DIR/channel.ini"
    checkfileexist "$CONF_FILE"
    $COMMAND ;;
  *) usage; exit 1;;
esac 
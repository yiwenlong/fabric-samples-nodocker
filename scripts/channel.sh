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

CONFIGTX_COMMON_TEMPLATE_FILE=$DIR/template/configtx-common-channel.yaml

COMMAND_PEER=$FABRIC_BIN/peer
COMMAND_CONFIGTXGEN=$FABRIC_BIN/configtxgen

. $DIR/utils/log-utils.sh
. $DIR/utils/conf-utils.sh
. $DIR/utils/file-utils.sh

function readValue {
    echo $(readConfValue $CONF_FILE $1)
}

function readNodeValue {
    echo $(readConfValue $CONF_FILE $1 $2)
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
    channel_name=$(readValue 'channel.name')
    channel_profile=$(readValue 'channel.profile')
    channel_orgs=$(readValue 'channel.orgs')
    channel_orderer=$(readValue 'channel.orderer')
    
    logInfo "Start config channel:" $channel_name

    # 2. Generate a directory for the channel to store files.
    channel_home=$WORK_HOME/$channel_name
    if [ -d $channel_home ]; then 
        rm -fr $channel_home
    fi 
    mkdir -p $channel_home
    cd $channel_home
    logInfo "Channel Home dir:" $channel_home

    # 3. Generate configtx.yaml.
    configtx_file=$channel_home/configtx.yaml
    echo "Organizations:" > $configtx_file
    peerorgs=(${channel_orgs//,/ })
    for org_name in ${peerorgs[@]}; do
        org_configtx_file=$WORK_HOME/$(readNodeValue $org_name 'org.configtx')
        if [ ! -f $org_configtx_file ]; then
            logError "File not found:" $org_configtx_file
            exit 1
        fi 
        cat $org_configtx_file >> $configtx_file
    done 
    # 3.2. Wirte common code. 
    cat $CONFIGTX_COMMON_TEMPLATE_FILE >> $configtx_file
    # 3.3. Write channel profile
    for org_name in ${peerorgs[@]}; do
        echo "                - *${org_name}" >> $configtx_file
    done 
    echo '            Capabilities:
                <<: *ApplicationCapabilities' >> $configtx_file
    logInfo "Channel tx config file has been generated: $configtx_file"

    # 4. Generate transaction file for create channel.
    channel_tx_file=$channel_home/$channel_name.tx
    $COMMAND_CONFIGTXGEN \
        -profile $channel_profile \
        -outputCreateChannelTx $channel_tx_file \
        -channelID $channel_name \
        -configPath $channel_home
    if [ ! $? == 0 ]; then
        logError "Transaction Generate Error:" $channel_tx_file
        exit 1
    fi
    logInfo "Channel transaction file has been generated:" $channel_tx_file
    
    # 5. Generate transaction files for update anchor peer.
    for org_name in ${peerorgs[@]}; do
        anchor_tx_file=$channel_home/${org_name}Panchors.tx
        $COMMAND_CONFIGTXGEN \
            -profile $channel_profile \
            -outputAnchorPeersUpdate $anchor_tx_file \
            -channelID $channel_name \
            -asOrg ${org_name} \
            -configPath $channel_home
        if [ ! $? == 0 ]; then
            logError "Transaction Generate Error:" $anchor_tx_file
            exit 1
        fi
        logInfo "Anchor peer transaction file for $org_name has been generated:" $anchor_tx_file
    done 

    # 6. Generate tool scripts for every peer node.
    orderer_tls_ca_file=$WORK_HOME/$(readNodeValue $channel_orderer 'org.tls.ca')
    orderer_address=$(readNodeValue $channel_orderer  "org.address")
    if [ ! -f $orderer_tls_ca_file ]; then
        logError "File not found:" $orderer_tls_ca_file
        exit 1
    fi 
    for org_name in ${peerorgs[@]}; do
        org_node_list=$(readNodeValue $org_name 'org.node.list')
        org_admin_msp_dir=$WORK_HOME/$(readNodeValue $org_name 'org.admin.msp.dir')
        org_msp_id=$(readNodeValue $org_name 'org.mspid')
        org_domain=$(readNodeValue $org_name 'org.domain')
        org_tls_ca_file=$WORK_HOME/$(readNodeValue $org_name 'org.tls.ca')
        if [ ! -d $org_admin_msp_dir ]; then 
            logError "MSP Directory not found:" $org_admin_msp_dir
            exit 1
        fi 
        if [ ! -f $org_tls_ca_file ]; then 
            logError "TLS CA file not found:" $org_tls_ca_file
            exit 1
        fi 
        peers=(${org_node_list//,/ })
        for node_name in ${peers[@]}; do
            channel_node_conf_home=$channel_home/$org_name-$node_name-$channel_name-conf
            mkdir -p $channel_node_conf_home

            channel_node_conf_file=$channel_node_conf_home/channel.conf

            cp $org_tls_ca_file $channel_node_conf_home/peer-tls-ca.pem
            cp $orderer_tls_ca_file $channel_node_conf_home/orderer-tls-ca.pem
            cp $channel_home/$channel_name.tx $channel_node_conf_home
            cp $channel_home/${org_name}Panchors.tx $channel_node_conf_home
            cp -r $org_admin_msp_dir $channel_node_conf_home/adminmsp

            node_domain=$node_name.$org_domain
            node_port=$(readNodeValue $org_name.$node_name 'node.port')

            echo "channel.name=$channel_name" > $channel_node_conf_file
            echo "channel.create.tx.file.name=$channel_name.tx" >> $channel_node_conf_file
            echo "orderer.address=$orderer_address" >> $channel_node_conf_file
            echo "orderer.tls.ca=orderer-tls-ca.pem" >> $channel_node_conf_file
            echo "org.anchorfile=${org_name}Panchors.tx" >> $channel_node_conf_file
            echo "org.name=$org_name" >> $channel_node_conf_file
            echo "org.mspid=$org_msp_id" >> $channel_node_conf_file
            echo "org.adminmsp=adminmsp" >> $channel_node_conf_file
            echo "org.peer.address=$node_domain:$node_port" >> $channel_node_conf_file
            echo "org.tls.ca=peer-tls-ca.pem" >> $channel_node_conf_file

            logSuccess "Channel config home for org: $org_name node: $node_name has been generated:" $channel_node_conf_home
        done 
    done 

    logSuccess "Channel config success:" $channel_name
}

function create {

    tx_file=$CONF_DIR/$(readValue "channel.create.tx.file.name")
    orderer_tls_file=$CONF_DIR/$(readValue "orderer.tls.ca")
    org_tls_file=$CONF_DIR/$(readValue "org.tls.ca")
    admin_msp_dir=$CONF_DIR/$(readValue "org.adminmsp")

    peer_address=$(readValue "org.peer.address")
    orderer_address=$(readValue "orderer.address")
    org_mspid=$(readValue "org.mspid")
    channel_name=$(readValue "channel.name")

    checkfileexist $tx_file
    checkfileexist $orderer_tls_file
    checkfileexist $org_tls_file
    checkdirexist $admin_msp_dir

    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH=$admin_msp_dir
    export CORE_PEER_LOCALMSPID=$org_mspid
    export CORE_PEER_ADDRESS=$peer_address
    export CORE_PEER_TLS_ROOTCERT_FILE=$org_tls_file

    block_file=$CONF_DIR/$channel_name.block

    $COMMAND_PEER channel create \
        -c $channel_name -f $tx_file \
        -o $orderer_address --tls --cafile $orderer_tls_file \
        --outputBlock $block_file
}

function join {
    admin_msp_dir=$CONF_DIR/$(readValue "org.adminmsp")
    org_mspid=$(readValue "org.mspid")
    peer_address=$(readValue "org.peer.address")
    org_tls_file=$CONF_DIR/$(readValue "org.tls.ca")
    channel_name=$(readValue "channel.name")
    logInfo "Join channel:" "$channel_name"
    logInfo "Organization admin msp directory:" "$admin_msp_dir"
    logInfo "Organization mspid:" "$org_mspid"
    logInfo "Organization node address:" "$peer_address"
    logInfo "Organization TLS ca file:" "$org_tls_file"
    checkdirexist "$admin_msp_dir"
    checkfileexist "$org_tls_file"

    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH=$admin_msp_dir
    export CORE_PEER_LOCALMSPID=$org_mspid
    export CORE_PEER_ADDRESS=$peer_address
    export CORE_PEER_TLS_ROOTCERT_FILE=$org_tls_file

    block_file=$CONF_DIR/$channel_name.block

    orderer_address=$(readValue "orderer.address")
    orderer_tls_file=$CONF_DIR/$(readValue "orderer.tls.ca")
    logInfo "Orderer address:" "$orderer_address"
    logInfo "Orderer TLS ca file:" "$orderer_tls_file"
    checkfileexist "$orderer_tls_file"

    if [ ! -f "$block_file" ]; then
        $COMMAND_PEER channel fetch newest "$block_file" \
            -o "$orderer_address" \
            -c "$channel_name" \
            --tls --cafile "$orderer_tls_file"
    fi

    $COMMAND_PEER channel join \
        -b "$block_file" \
        -o "$orderer_address" --tls --cafile "$orderer_tls_file"

    if [ $? -eq 0 ]; then
        logSuccess "Join channel success:" "$peer_address -> $channel_name"
        $COMMAND_PEER channel list
    else
        logError "Join channel failed:" "$peer_address -> $channel_name"
        exit 1
    fi
}

function updateAnchorPeer {

    admin_msp_dir=$CONF_DIR/$(readValue "org.adminmsp")
    org_mspid=$(readValue "org.mspid")
    peer_address=$(readValue "org.peer.address")
    org_tls_file=$CONF_DIR/$(readValue "org.tls.ca")

    channel_name=$(readValue "channel.name")

    checkdirexist $admin_msp_dir
    checkfileexist $org_tls_file

    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_MSPCONFIGPATH=$admin_msp_dir
    export CORE_PEER_LOCALMSPID=$org_mspid
    export CORE_PEER_ADDRESS=$peer_address
    export CORE_PEER_TLS_ROOTCERT_FILE=$org_tls_file

    orderer_address=$(readValue "orderer.address")
    orderer_tls_file=$CONF_DIR/$(readValue "orderer.tls.ca")
    anchor_tx_file=$CONF_DIR/$(readValue "org.anchorfile")

    checkfileexist $orderer_tls_file

    checkfileexist $anchor_tx_file

    $COMMAND_PEER channel update \
        -c $channel_name -f $anchor_tx_file \
        -o $orderer_address --tls --cafile $orderer_tls_file
}

function usage {
    echo "USAGE:"
    echo "  channel.sh <commadn> -f configfile"
    echo "      command: [ config | create | join | updateAnchorPeer | usage ]"
}

COMMAND=$1
if [ ! $COMMAND ]; then 
    usage
    exit 1
fi 
shift

CONF_FILE=
CONF_DIR=

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
    CONF_FILE=$CONF_DIR/channel.conf
    checkfileexist "$CONF_FILE"
    $COMMAND ;;
  *) usage; exit 1;;
esac 
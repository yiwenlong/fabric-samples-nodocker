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

COMMAND_PEER=$FABRIC_BIN/peer

. "$DIR"/utils/log-utils.sh
. "$DIR"/utils/conf-utils.sh
. "$DIR"/utils/file-utils.sh

function absolute() {
  echo $(absolutefile $1 "$WORK_HOME")
}

function confValue() {
  echo $(readConfValue $CONF_FILE $1)
}

function channelValue() {
  echo $(readConfValue $CHANNEL_CONF_FILE $1)
}

function usage() {
  echo "usage"
}

function package {
  logInfo "Start package chaincode:" "$CONF_FILE"

  cc_name=$(confValue chaincode.name)
  cc_address=$(confValue chaincode.address)
  cc_binary=$(absolute $(confValue chaincode.binary.file))
  logInfo "Chaincode Nmae:" "$cc_name"
  logInfo "Chaincode Address:" "$cc_address"
  logInfo "Chaincode Binary:" "$cc_binary"
  checkfileexist "$cc_binary"

  cc_home=$WORK_HOME/chaincode-home-$(basename -s .conf "$CONF_FILE")
  mkdir -p "$cc_home" && rm -fr "$cc_home"/* && cd "$cc_home"
  logInfo "Chaincode work home generated:" "$cc_home"

  cp "$CONF_FILE" "$cc_home"/chaincode.conf
  cp "$cc_binary" "$cc_home"/

  cc_connection_file=$cc_home/connection.json
  echo '{"address": "'"$cc_address"'","dial_timeout": "10s","tls_required": false,"client_auth_required": false}' > "$cc_connection_file"
  logInfo "connection.json generated:" "$cc_connection_file"

  cc_metadate_file=$cc_home/metadata.json
  echo '{"path":"","type":"external","label":"'"$cc_name"'"}' > "$cc_metadate_file"
  logInfo "metadata.json generated:" "$cc_metadate_file"

  tar czfP code.tar.gz connection.json
  tar czfP "$cc_name".tar.gz code.tar.gz metadata.json
  logInfo "$cc_name"'.tar.gz generated:' "$cc_home/$cc_name".tar.gz

  logSuccess "Chaincde package success! Check Work Directory:" "$cc_home"
}

function install() {
  cc_name=$(confValue chaincode.name)
  cc_binary=$(absolutefile $(confValue chaincode.binary.file) "$CC_HOME")
  cc_package=$(absolutefile "$cc_name".tar.gz "$CC_HOME")
  logInfo "Chaincode name:" "$cc_name"
  logInfo "Chaincode binary file:" "$cc_binary"
  logInfo "Chaincode package file:" "$cc_package"
  checkfileexist "$cc_binary"
  checkfileexist "$cc_package"

  ch_name=$(channelValue channel.name)
  org_name=$(channelValue org.name)
  logInfo "Channel name:" "$ch_name"
  logInfo "Organization name:" "$org_name"

  org_admin_msp_dir="$CHANNEL_HOME"/$(channelValue org.adminmsp)
  org_mspid=$(channelValue org.mspid)
  org_tls_ca="$CHANNEL_HOME"/$(channelValue org.tls.ca)
  node_address=$(channelValue org.peer.address)
  logInfo "Organization admin msp directory:" "$org_admin_msp_dir"
  logInfo "Organization msp id:" "$org_mspid"
  logInfo "Organization TLS ca file:" "$org_tls_ca"
  logInfo "Organization node_address:" "$node_address"
  checkdirexist "$org_admin_msp_dir"
  checkfileexist "$org_tls_ca"

  export CORE_PEER_MSPCONFIGPATH="$org_admin_msp_dir"
  export CORE_PEER_LOCALMSPID="$org_mspid"
  export CORE_PEER_ADDRESS="$node_address"
  export CORE_PEER_TLS_ROOTCERT_FILE="$org_tls_ca"

  $COMMAND_PEER lifecycle chaincode install "$cc_package"
  if [ $? -eq 0 ]; then
      logSuccess "Chaincode install success:" "$cc_name"
  else
      logError "Chaincode install failed:" "$cc_name"
      exit 1
  fi

  cc_package_id=$($COMMAND_PEER lifecycle chaincode queryinstalled | grep "$cc_name" | awk -F 'Package ID: ' '{print $2}' | awk -F ',' '{print $1;exit}')
  echo "chaincode.package.id=${cc_package_id}" >> "$CONF_FILE"
  logInfo "Chaincode PackageId:" "$cc_package_id"
}

function approve() {
  ch_name=$(channelValue channel.name)
  cc_name=$(confValue chaincode.name)
  cc_version=$(confValue chaincode.version)
  cc_package_id=$(confValue chaincode.package.id)
  cc_sequence=$(confValue chaincode.sequence)

  logInfo "Approve chaincode:" "$cc_name"
  logInfo "Chaincode version:" "$cc_version"
  logInfo "Chaincode package id:" "$cc_package_id"
  logInfo "Chaincode sequence:" "$cc_sequence"
  logInfo "Channel name:" "$cc_name"

  ch_orderer_address=$(channelValue orderer.address)
  ch_orderer_tls_ca=$CHANNEL_HOME/$(channelValue orderer.tls.ca)
  logInfo "Orderer address:" "$ch_orderer_address"
  logInfo "Orderer TLS ca file:" "$ch_orderer_tls_ca"
  checkfileexist "$ch_orderer_tls_ca"

  org_name=$(channelValue org.name)
  org_admin_msp_dir=$CHANNEL_HOME/$(channelValue org.adminmsp)
  org_mspid=$(channelValue org.mspid)
  org_tls_ca=$CHANNEL_HOME/$(channelValue org.tls.ca)
  org_peer_address=$(channelValue org.peer.address)
  logInfo "Organization name:" "$org_name"
  logInfo "Organization admin msp directory:" "$org_admin_msp_dir"
  logInfo "Organization msp id:" "$org_mspid"
  logInfo "Organization TLS ca file:" "$org_tls_ca"
  logInfo "Organization node address:" "$org_peer_address"
  checkfileexist "$org_tls_ca"
  checkdirexist "$org_admin_msp_dir"

  export CORE_PEER_MSPCONFIGPATH="$org_admin_msp_dir"
  export CORE_PEER_LOCALMSPID="$org_mspid"
  export CORE_PEER_ADDRESS="$org_peer_address"
  export CORE_PEER_TLS_ROOTCERT_FILE="$org_tls_ca"
  export CORE_PEER_TLS_ENABLE=true

  $COMMAND_PEER lifecycle chaincode approveformyorg \
        --channelID "$ch_name" \
        --name "$cc_name" \
        --version "$cc_version" \
        --init-required \
        --package-id "$cc_package_id" \
        --sequence "$cc_sequence" \
        --tls true \
        --orderer "$ch_orderer_address" \
        --cafile "$ch_orderer_tls_ca"

    if [ $? -eq 0 ]; then
        logSuccess "Chaincode approve success:" "$org_name -> $cc_package_id"
    else
        logError "Chaincode approve failed:" "$org_name -> $cc_package_id"
        exit 1
    fi

    $COMMAND_PEER lifecycle chaincode checkcommitreadiness \
        --channelID "$ch_name" \
        --name "$cc_name" \
        --version "$cc_version" \
        --init-required \
        --sequence "$cc_sequence" \
        --tls true \
        --orderer "$ch_orderer_address" \
        --cafile "$ch_orderer_tls_ca" \
        --output json
}

command=$1
shift

while getopts f:h:c:p:n:v:i opt
do 
    case $opt in 
        f) CONF_FILE=$(absolute "$OPTARG"); checkfileexist "$CONF_FILE";;
        h) CC_HOME=$(absolute "$OPTARG"); checkdirexist "$CC_HOME";;
        c) CHANNEL_HOME=$(absolute "$OPTARG"); checkdirexist "$CHANNEL_HOME";;
        p) PROC_NAME="$OPTARG";;
        n) CC_NAME="$OPTARG";;
        v) CC_PARAMS="$OPTARG";;
        i) CC_IS_INIT="--isInit";;
        *) usage; exit 1;;
    esac 
done 

case $command in 
    package) 
        checkfileexist "$CONF_FILE"
        $command ;;
    install | approve)
      checkdirexist "$CC_HOME"
      checkdirexist "$CHANNEL_HOME"
      CONF_FILE="$CC_HOME"/chaincode.conf
      CHANNEL_CONF_FILE="$CHANNEL_HOME"/channel.conf
      checkfileexist "$CONF_FILE"
      checkfileexist "$CHANNEL_CONF_FILE"
      $command;;
    *) usage;;
esac
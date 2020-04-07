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
  checkfielexist "$cc_binary"

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

command=$1
shift

while getopts f:h:c:p:n:v:i opt
do 
    case $opt in 
        f) CONF_FILE=$(absolute "$OPTARG"); checkfielexist "$CONF_FILE";;
        h) CC_HOME=$(absolute "$OPTARG"); checkfielexist "$CC_HOME";;
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
        checkfielexist "$CONF_FILE"
        $command ;;
    *) usage;;
esac
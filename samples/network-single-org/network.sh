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

export FABRIC_BIN=$(cd "$DIR"/../../build/bin && pwd)
export SCRIPT_PATH=$(cd "$DIR"/../../scripts && pwd)

# shellcheck source=utils/log-utils.sh
. "$SCRIPT_PATH"/utils/log-utils.sh
# shellcheck source=utils/file-utils.sh
. "$SCRIPT_PATH"/utils/file-utils.sh

checkdirexist "$FABRIC_BIN"
checkdirexist "$SCRIPT_PATH"

echo "========================= FABRIC BINARY VERSION ==========================="
"$FABRIC_BIN/peer" version
"$FABRIC_BIN/orderer" version
"$FABRIC_BIN/cryptogen" version
echo "==========================================================================="
exit
function checkSuccess() {
    if [[ $? != 0 ]]; then
        exit $?
    fi
}

function config() {
  logInfo "Config organization:" Org1
  "$SCRIPT_PATH"/peer.sh configorg -f Org1.ini
  checkSuccess
  logInfo "Config orderer organization:" Orderer
  "$SCRIPT_PATH"/orderer.sh configorg -f Orderer.ini
  checkSuccess
}

function start() {
  logInfo "Start organization nodes:" Org1
  "$SCRIPT_PATH"/peer.sh startorg -d Org1
  checkSuccess
  logInfo "Start orderer:" Orderer
  "$SCRIPT_PATH"/orderer.sh startnode -d Orderer/orderer0
  checkSuccess
  "$SCRIPT_PATH"/orderer.sh startnode -d Orderer/orderer1
  checkSuccess
  "$SCRIPT_PATH"/orderer.sh startnode -d Orderer/orderer2
  checkSuccess
  sleep 3
  supervisorctl status
}

function createChannel() {
  cd "$DIR/channel-mychannel" && "./create.sh"
  checkSuccess
}

function installChaincode() {
  cd "$DIR/chaincode-tps" && "./install.sh"
  checkSuccess
}

function down() {
  logInfo "Down organization:" Org1
  "$SCRIPT_PATH"/peer.sh stoporg -d Org1
  logInfo "Clean organization:" Org1
  rm -fr "$DIR"/Org1
  logInfo "Down orderer:" Orderer
  "$SCRIPT_PATH"/orderer.sh stoporg -d Orderer
  logInfo "Clean orderer:" Orderer
  rm -fr "$DIR"/Orderer
  logInfo "Clean channel:" Orderer
  ./channel-mychannel/clean.sh
  logInfo "Clean chaincode:" Orderer
  ./chaincode-tps/clean.sh
  logSuccess "Network stop!"
}

function usage() {
  echo "USAGE:"
  echo "  network.sh [ up | down | config | start]"
}

COMMAND=$1
case $COMMAND in 
  up)
    config && start && createChannel && installChaincode;;
  start)
    config && start ;;
  config)
    config ;;
  down)
    down ;;
  *) usage;;
esac
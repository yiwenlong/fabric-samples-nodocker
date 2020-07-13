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

function config() {
  logInfo "Config organization:" Org1
  if ! "$SCRIPT_PATH"/peer.sh configorg -f Org1.ini; then
    exit $?
  fi
  logInfo "Config orderer organization:" Orderer
  if ! "$SCRIPT_PATH"/orderer.sh configorg -f Orderer.ini; then
    exit $?
  fi
}

function start() {
  logInfo "Start organization nodes:" Org1
  if ! "$SCRIPT_PATH"/peer.sh startorg -d Org1; then
    exit $?
  fi
  logInfo "Start orderer:" Orderer
  if ! "$SCRIPT_PATH"/orderer.sh startnode -d Orderer/orderer0; then
    exit $?
  fi
  if ! "$SCRIPT_PATH"/orderer.sh startnode -d Orderer/orderer1; then
    exit $?
  fi
  if ! "$SCRIPT_PATH"/orderer.sh startnode -d Orderer/orderer2; then
    exit $?
  fi
  sleep 3
  supervisorctl status
}

function stop() {
  logInfo "Start organization nodes:" Org1
  if ! "$SCRIPT_PATH"/peer.sh stoporg -d Org1; then
    exit $?
  fi
  logInfo "Start orderer:" Orderer
  if ! "$SCRIPT_PATH"/orderer.sh stopnode -d Orderer/orderer0; then
    exit $?
  fi
  if ! "$SCRIPT_PATH"/orderer.sh stopnode -d Orderer/orderer1; then
    exit $?
  fi
  if ! "$SCRIPT_PATH"/orderer.sh stopnode -d Orderer/orderer2; then
    exit $?
  fi
  sleep 3
  supervisorctl status
}

function createChannel() {
  cd "$DIR/channel-mychannel" || exit
  if ! "./create.sh"; then
    exit $?
  fi
}

function installChaincode() {
  cd "$DIR/chaincode-tps" || exit
  if ! "./install.sh"; then
    exit $?
  fi
}

function down() {
  logInfo "Down organization:" Org1
  "$SCRIPT_PATH"/peer.sh stoporg -d Org1
  logInfo "Clean organization:" Org1
  if [ -d "$DIR/Org1" ]; then
    rm -fr "$DIR/Org1"
  fi

  logInfo "Down orderer:" Orderer
  "$SCRIPT_PATH"/orderer.sh stoporg -d Orderer
  logInfo "Clean orderer:" Orderer
  if [ -d "$DIR/Orderer" ]; then
    rm -fr "$DIR/Orderer"
  fi

  logInfo "Clean channel:" Orderer
  if [ -f "./channel-mychannel/clean.sh" ]; then
    "./channel-mychannel/clean.sh"
  fi

  logInfo "Clean chaincode:" Orderer
  if [ -f "./chaincode-tps/clean.sh" ]; then
    ./chaincode-tps/clean.sh
  fi
  logSuccess "Network stop!"
}

function usage() {
  echo "USAGE:"
  echo "  network.sh [ up | down | config | start]"
}

COMMAND=$1
case $COMMAND in 
  up)
    config
    start
    createChannel
    installChaincode
    ;;
  start)
    config
    start ;;
  config | stop | clean)
    "$COMMAND" ;;
  down)
    down ;;
  *) usage;;
esac
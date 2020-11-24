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

arch=$(uname -s|tr '[:upper:]' '[:lower:]')

export FABRIC_BIN=$(cd "$DIR"/../../binaries/"$arch"/fabric && pwd)
export SCRIPT_PATH=$(cd "$DIR"/../../scripts && pwd)

# shellcheck source=utils/log-utils.sh
. "$SCRIPT_PATH"/utils/log-utils.sh
# shellcheck source=utils/file-utils.sh
. "$SCRIPT_PATH"/utils/file-utils.sh

checkdirexist "$FABRIC_BIN"
checkdirexist "$SCRIPT_PATH"

function config() {
  logInfo "Config organization:" Org1
  if ! "$SCRIPT_PATH"/config-peer.sh -f Org1.ini; then
    exit $?
  fi
  logInfo "Config orderer organization:" Orderer
  if ! "$SCRIPT_PATH"/config-orderer.sh -f Orderer.ini; then
    exit $?
  fi
}

function start() {
  logInfo "Start organization nodes:" Org1
  for node_num in 0 1; do
    "$DIR/Org1/peer$node_num/boot.sh"
  done
  logInfo "Start orderer:" Orderer
  for node_num in 0 1 2; do
    "$DIR/Orderer/orderer$node_num/boot.sh"
  done
}

function stop() {
  logInfo "Stop organization nodes:" Org1
  for node_num in 0 1; do
    "$DIR/Org1/peer$node_num/stop.sh"
  done
  logInfo "Stop orderer:" Orderer
  for node_num in 0 1 2; do
    "$DIR/Orderer/orderer$node_num/stop.sh"
  done
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

function clean() {
  read -r -p "Are You Sure Clean Fabric Network Running Data? [Y/n] " input
  case $input in
    [yY][eE][sS]|[yY])
    for node in "peer0" "peer1"; do
      if [ -d "Org1/$node/data" ]; then
        rm -fr "Org1/$node/data"
      fi
      if [ -f "Org1/$node/FABRIC-NODOCKER-Org1-$node.log" ]; then
        rm -f "Org1/$node/FABRIC-NODOCKER-Org1-$node.log"
      fi
    done

    for node in "orderer0" "orderer1" "orderer2"; do
      if [ -d "Orderer/$node/etcdraft" ]; then
        rm -fr "Orderer/$node/etcdraft"
      fi
      if [ -d "Orderer/$node/file-ledger" ]; then
        rm -fr "Orderer/$node/file-ledger"
      fi
      if [ -f "Orderer/$node/FABRIC-NODOCKER-Orderer-$node.log" ]; then
        rm -f "Orderer/$node/FABRIC-NODOCKER-Orderer-$node.log"
      fi
    done
    echo "Clean Done!"
  esac
}

function down() {
  logInfo "Clean organization:" Org1
  if [ -d "$DIR/Org1" ]; then
    rm -fr "$DIR/Org1"
  fi
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
#    installChaincode
    ;;
  start)
    config
    start ;;
  config | stop | clean)
    "$COMMAND" ;;
  down)
    stop
    down ;;
  *) usage;;
esac
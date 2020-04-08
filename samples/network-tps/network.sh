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

export FABRIC_BIN=$(cd "$DIR"/../../fabric-bin/darwin && pwd)
export SCRIPT_PATH=$(cd "$DIR"/../../scripts && pwd)

. "$SCRIPT_PATH"/utils/log-utils.sh

function networksetup() {
    startPeerOrg
    startOrdererOrg
    upChannel
    upChaincode
}

function startPeerOrg() {
    logInfo "Config organization:" Org1
    "$SCRIPT_PATH"/peer.sh configorg -f Org1.conf
    logInfo "Start organization nodes:" Org1
    "$SCRIPT_PATH"/peer.sh startorg -o"" Org1
    logSuccess "Organization started:" Org1
}

function startOrdererOrg() {
    logInfo "Config orderer:" Orderer
    "$SCRIPT_PATH"/orderer.sh configorg -f Orderer.conf
    echo "Start orderer:" Orderer
    "$SCRIPT_PATH"/orderer.sh startorg -o Orderer
    logSuccess "Orderer started:" Orderer
}

function upChannel() {
    export FABRIC_CFG_PATH=$(cd "$DIR"/Org1/peer0 && pwd)
    logInfo "Config channel:" mychannel
    "$SCRIPT_PATH"/channel.sh config -f mychannel.conf
    logInfo "Create channel:" mychannel
    "$SCRIPT_PATH"/channel.sh create -d $(cd "$DIR"/mychannel/Org1-peer0-mychannel-conf && pwd)
    logInfo "Join channel:" "org1.peer0 -> mychannel"
    "$SCRIPT_PATH"/channel.sh join -d $(cd "$DIR"/mychannel/Org1-peer0-mychannel-conf && pwd)
    logInfo "Join channel:" "org1.peer1 -> mychannel"
    "$SCRIPT_PATH"/channel.sh join -d $(cd "$DIR"/mychannel/Org1-peer1-mychannel-conf && pwd)
    logInfo "Update channel:" "Achor peer for mychannel -> peer0"
    "$SCRIPT_PATH"/channel.sh updateAnchorPeer -d $(cd "$DIR"/mychannel/Org1-peer0-mychannel-conf && pwd)
    logSuccess "Channel created:" mychannel
}

function upChaincode() {
  export FABRIC_CFG_PATH=$(cd "$DIR"/Org1/peer0 && pwd)
  logInfo "Package chaincode:" tps
  "$SCRIPT_PATH"/chaincode.sh package -f cc-tps.conf
  logInfo "Install chaincode:" "tps -> org1.peer0"
  "$SCRIPT_PATH"/chaincode.sh install -h chaincode-home-cc-tps -c mychannel/Org1-peer0-mychannel-conf
  logInfo "Install chaincode:" "tps -> org1.peer0"
  "$SCRIPT_PATH"/chaincode.sh install -h chaincode-home-cc-tps -c mychannel/Org1-peer1-mychannel-conf
  logInfo "Approve chaincode:" "tps"
  "$SCRIPT_PATH"/chaincode.sh approve -h chaincode-home-cc-tps -c mychannel/Org1-peer0-mychannel-conf
}

function networkdown() {
    logInfo "Down organization:" Org1
    "$SCRIPT_PATH"/peer.sh stoporg -o Org1
    logInfo "Clean organization:" Org1
    rm -fr "$DIR"/Org1
    logInfo "Down orderer:" Orderer
    "$SCRIPT_PATH"/orderer.sh stoporg -o Orderer
    logInfo "Clean orderer:" Orderer
    rm -fr "$DIR"/Orderer
    logInfo "Clean channel:" mychannel
    rm -fr "$DIR"/mychannel
    supervisorctl reload > /dev/null
    logInfo "Clean chaincode:" tps
    rm -fr "$DIR"/chaincode-home-cc-tps
    logSuccess "Network stoped!"
}

function usage() {
    echo "USAGE"
    exit 0
}

COMMAND=$1
case $COMMAND in 
    up) 
        networksetup ;;
    upchannel)
        upChannel;;
    upchaincode)
      upChaincode;;
    upnodes)
        startPeerOrg
        startOrdererOrg;;
    down) networkdown ;;
    *) usage;;
esac
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

function networksetup() {
    startPeerOrg
    startOrdererOrg
    upChannel
}

function startPeerOrg() {
    echo "开始配置组织: Org1"
    "$SCRIPT_PATH"/peer.sh configorg -f Org1.conf
    echo "开始启动组织: Org1"
    "$SCRIPT_PATH"/peer.sh startorg -o Org1
}

function startOrdererOrg() {
    echo "开始配置组织: Orderer"
    "$SCRIPT_PATH"/orderer.sh configorg -f Orderer.conf
    echo "开始启动组织: Orderer"
    "$SCRIPT_PATH"/orderer.sh startorg -o Orderer
}

function upChannel() {
    export FABRIC_CFG_PATH=$(cd "$DIR"/Org1/peer0 && pwd)
    echo "开始配置 channel: mychannel"
    "$SCRIPT_PATH"/channel.sh config -f mychannel.conf
    echo "开始创建 channel: mychannel"
    "$SCRIPT_PATH"/channel.sh create -d $(cd "$DIR"/mychannel/Org1-peer0-mychannel-conf && pwd)
    echo "节点 peer0 加入 channel: mychannel"
    "$SCRIPT_PATH"/channel.sh join -d $(cd "$DIR"/mychannel/Org1-peer0-mychannel-conf && pwd)
    echo "节点 peer1 加入 channel: mychannel"
    "$SCRIPT_PATH"/channel.sh join -d $(cd "$DIR"/mychannel/Org1-peer1-mychannel-conf && pwd)
    echo "更新组织 Org1 在 mychannel 中的 anchor peer 节点: peer0"
    "$SCRIPT_PATH"/channel.sh updateAnchorPeer -d $(cd "$DIR"/mychannel/Org1-peer0-mychannel-conf && pwd)
}

function networkdown() {
    echo "开始停止组织进程: Org1"
    "$SCRIPT_PATH"/peer.sh stoporg -o Org1
    echo "开始清理组织: Org1"
    rm -fr $DIR/Org1
    echo "开始停止组织进程: Orderer"
    "$SCRIPT_PATH"/orderer.sh stoporg -o Orderer
    echo "开始清理组织: Orderer"
    rm -fr "$DIR"/Orderer
    echo "开始清理 channel: mychannel"
    rm -fr "$DIR"/mychannel
    supervisorctl reload > /dev/null
    echo "网络节点已停止并清理"
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
    upnodes)
        startPeerOrg
        startOrdererOrg;;
    down) networkdown ;;
    *) usage;;
esac
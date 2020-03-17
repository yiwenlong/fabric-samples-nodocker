#!/bin/bash
#
# Copyright 2020 Yiwenlong(wlong.yi#gmail.com)
 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
 
#    http://www.apache.org/licenses/LICENSE-2.0
 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

function networksetup() {
    echo "开始配置组织: Org1"
    ../../scripts/peer.sh configorg -f Org1.conf 
    echo "开始启动组织: Org1"
    ../../scripts/peer.sh startorg -o Org1
    echo "开始配置组织: Orderer"
    ../../scripts/orderer.sh configorg -f Orderer.conf 
    echo "开始启动组织: Orderer"
    ../../scripts/orderer.sh startorg -o Orderer
}

function networkdown() {
    echo "开始停止组织进程: Org1"
    ../../scripts/peer.sh stoporg -o Org1
    echo "开始清理组织: Org1"
    rm -fr Org1
    echo "开始停止组织进程: Orderer"
    ../../scripts/orderer.sh stoporg -o Orderer
    echo "开始清理组织: Orderer"
    rm -fr Orderer
    echo "网络节点已停止并清理"
}

function usage() {
    echo "USAGE"
    exit 0
}

COMMAND=$1
case $COMMAND in 
    up) 
        if [ ! $FABRIC_BIN ]; then 
            echo "缺少环境变量: " FABRIC_BIN
            exit 1
        fi 
        networksetup ;;
    down) networkdown ;;
    *) usage;;
esac
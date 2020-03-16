#!/bin/bash

function networksetup() {
    echo "开始配置组织: Org1"
    ../../scripts/peer.sh configorg -f Org1.conf 
    echo "开始启动组织: Org1"
    ../../scripts/peer.sh startorg -o Org1
}

function networkdown() {
    echo "开始停止组织进程: Org1"
    ../../scripts/peer.sh stoporg -o Org1
    echo "开始清理组织: Org1"
    rm -fr Org1
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
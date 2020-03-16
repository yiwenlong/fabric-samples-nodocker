#!/bin/bash

function networksetup() {
    if [ ! -d $BCP_FABRIC_BIN ]; then 
        echo "缺少环境变量: " BCP_FABRIC_BIN
        exit 1
    fi 
    echo "开始配置组织: Org1"
    ../../scripts/peer.sh configorg -f Org1.conf 
    echo "开始启动组织: Org1"
    ../../scripts/peer.sh startorg -o Org1
}

function usage() {
    echo "USAGE"
    exit 0
}

COMMAND=$1
case $COMMAND in 
    up) networksetup ;;
    *) usage;;
esac
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

CRYPTO_CONFIG_TEMPLATE_FILE=$DIR/template/crypto-config-peer.yaml
ORG_CONFIGTX_TEMPLATE_FILE=$DIR/template/configtx-peer.yaml
CORE_TEMPLATE_FILE=$DIR/template/core.yaml

DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH=$DIR/chaincode-builder
CHAINCODE_EXTERNAL_BUILDER_NAME=my_external_builder
CHAINCODE_EXTERNAL_BUILDER_PATH=my_external_builder

COMMAND_CRYPTOGEN=$FABRIC_BIN/cryptogen
COMMAND_PEER=$FABRIC_BIN/peer

. $DIR/utils/log-utils.sh
. $DIR/utils/conf-utils.sh

function readConfOrgValue() {
    echo $(readConfValue $CONF_FILE 'org' $1)
}

function readConfPeerValue() {
    echo $(readConfValue $CONF_FILE $1 $2)
}

# 根据 配置文件 和 节点名称配置节点
function configNode {
    node_name=$1

    # 1. 从配置文件读取配置信息
    node_port=$(readConfPeerValue $node_name 'peer.port')
    node_chaincode_port=$(readConfPeerValue $node_name 'peer.chaincode.port')
    node_operations_port=$(readConfPeerValue $node_name 'peer.operations.port')
    node_gossip_node=$(readConfPeerValue $node_name 'peer.gossip.node')

    # 2. 创建节点配置目录
    org_name=$(readConfOrgValue 'org.name')
    org_home=$WORK_HOME/$org_name
    node_home=$org_home/$node_name
    if [ -d $node_home ]; then 
        rm -fr $node_home
    fi 
    mkdir -p $node_home
    cd $node_home

    # 3. 将 external builder 和 msp 证书文件复制到节点的工作目录
    org_domain=$(readConfOrgValue 'org.domain')
    node_domain=$node_name.$org_domain
    cp -r $DEFAULT_CHAINCODE_EXTERNAL_BUILDER_PATH $node_home/$CHAINCODE_EXTERNAL_BUILDER_PATH
    cp -r $org_home/crypto-config/peerOrganizations/$org_domain/peers/$node_domain/* $node_home

    # 4. 生成节点的 core.yaml 配置文件
    org_mspid=$(readConfOrgValue 'org.mspid')
    gossip_node_port=$(readConfPeerValue $node_gossip_node 'peer.port')
    core_file=$node_home/core.yaml
    sed -e "s/<peer.name>/${node_name}/
    s/<peer.mspid>/${org_mspid}/
    s/<peer.address>/${node_domain}:${node_port}/
    s/<peer.domain>/${node_domain}/
    s/<peer.gossip.address>/${node_gossip_node}.${org_domain}:${gossip_node_port}/
    s/<peer.operations.port>/${node_operations_port}/
    s/<peer.couchdb.address>/${node_couchdb_address}/
    s/<peer.couchdb.username>/${node_couchdb_user}/
    s/<peer.couchdb.password>/${node_couchdb_pwd}/
    s/<peer.chaincode.builder.path>/${CHAINCODE_EXTERNAL_BUILDER_PATH}/
    s/<peer.chaincode.builder.name>/${CHAINCODE_EXTERNAL_BUILDER_NAME}/
    s/<peer.chaincode.address>/${node_domain}:${node_chaincode_port}/" $CORE_TEMPLATE_FILE > $core_file
    logInfo "$node_name 节点启动配置文件已生成:" "$core_file"

    # 5. 生成 supervisor 启动节点的配置文件
    supervisor_process_name=fabric-$org_name-$node_name
    supervisor_conf_file_name=$supervisor_process_name.ini
    supervisor_conf_file=$node_home/$supervisor_conf_file_name
    echo "[program:$supervisor_process_name]" > $supervisor_conf_file
    echo "command=$COMMAND_PEER node start" >> $supervisor_conf_file
    echo "directory=${node_home}" >> $supervisor_conf_file
    echo "redirect_stderr=true" >> $supervisor_conf_file
    echo "stdout_logfile=${node_home}/peer.log" >> $supervisor_conf_file
    echo "stdout_logfile_maxbytes=20MB" >> $supervisor_conf_file
    echo "stdout_logfile_backups=2" >> $supervisor_conf_file
    logInfo "$node_name 节点 supervisor 配置文件已生成:" $supervisor_conf_file
    logSuccess "节点配置完成:" $node_name

    # 6. 生成启动脚本
    boot_script_file=$node_home/boot.sh
    echo '#!/bin/bash' > $boot_script_file
    echo 'export FABRIC_CFG_PATH=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)' >> $boot_script_file
    echo 'if [ -f /usr/local/etc/supervisor.d/'$supervisor_conf_file_name' ]; then' >> $boot_script_file
    echo '  rm /usr/local/etc/supervisor.d/'$supervisor_conf_file_name'' >> $boot_script_file
    echo 'fi' >> $boot_script_file
    echo 'ln '$supervisor_conf_file' /usr/local/etc/supervisor.d/' >> $boot_script_file
    echo 'supervisorctl update' >> $boot_script_file
    echo 'echo 正在启动节点: '$node_name'' >> $boot_script_file
    echo 'sleep 1' >> $boot_script_file
    echo 'supervisorctl status' >> $boot_script_file
    chmod u+x $boot_script_file
    logSuccess "启动脚本已生成: " $boot_script_file

    # 7. 生成停止节点进程脚本
    stop_script_file=$node_home/stop.sh
    echo '#!/bin/bash' > $stop_script_file
    echo 'supervisorctl stop '$supervisor_process_name >> $stop_script_file
    echo 'rm /usr/local/etc/supervisor.d/'$supervisor_conf_file_name >> $stop_script_file
    echo 'supervisorctl remove '$supervisor_process_name >> $stop_script_file
    logSuccess "停止脚本已生成: " $boot_script_file
}

# 根据配置文件生成一个 Peer 组织
# 1. 从配置文件中读取配置信息
function config {
    # 0. 检查
    if [ ! -x $CRYPTOGEN_COMMAND ]; then 
        logError "配置错误" "请检查 FABRIC_BIN 环境变量"
        logInfo "export FABRIC_BIN="
        exit 1
    fi 

    # 1. 从配置文件中读取配置信息
    org_name=$(readConfOrgValue 'org.name')
    org_mspid=$(readConfOrgValue 'org.mspid')
    org_domain=$(readConfOrgValue 'org.domain')
    org_node_count=$(readConfOrgValue 'org.node.count')
    org_user_count=$(readConfOrgValue 'org.user.count')
    org_anchor_peer=$(readConfOrgValue 'org.anchor.peer')
    if [ ! $org_name ]; then 
        logError "参数错误:" "org.name"
        exit 1
    fi  

    # 2. 创建组织配置目录
    org_home=$WORK_HOME/$org_name
    if [ -d $org_home ]; then 
        rm -fr $org_home
    fi 
    mkdir -p $org_home
    cd $org_home

    # 3. 生成 MSP 配置文件
    msp_conf_file=$org_home/crypto-config.yaml
    sed -e "s/<org.name>/${org_name}/
    s/<org.domain>/${org_domain}/
    s/<org.peer.count>/${org_node_count}/
    s/<org.peer.user.count>/${org_user_count}/" $CRYPTO_CONFIG_TEMPLATE_FILE > $msp_conf_file
    logSuccess "组织 MSP 配置文件已生成: " $msp_conf_file
    msg=$($COMMAND_CRYPTOGEN generate --config=$msp_conf_file)
    if [ $? -eq 0 ]; then 
        logSuccess "$org_name MSP证书文件已生成"
    else
        logError "cryptogen 错误: " $msg
        exit 1
    fi 

    # 4. 生成 configtx 的 peerorg 部分
    org_msp_dir=$org_home/crypto-config/peerOrganizations/$org_domain/msp
    org_anchor_peeer_host=$org_anchor_peer.$org_domain
    org_anchor_peeer_port=$(readConfPeerValue $org_anchor_peer 'peer.port')
    configtx_file=$org_home/configtx-org.yaml
    sed -e "s/<org.name>/${org_name}/
    s/<org.mspid>/${org_mspid}/
    s/<org.mspid>/${org_mspid}/
    s/<org.mspid>/${org_mspid}/
    s:<org.msp.dir>:${org_msp_dir}:
    s/<org.anchor.host>/${org_anchor_peeer_host}/
    s/<org.anchor.port>/${org_anchor_peeer_port}/" $ORG_CONFIGTX_TEMPLATE_FILE > $configtx_file
    logSuccess "组织 configtx 配置文件已生成:" $configtx_file

    # 5. 配置 Peer 节点
    for (( i = 0; i < $org_node_count ; ++i)); do
        configNode peer$i
    done
}

function usage {
    echo "USAGE:"
    echo "  peer.sh <command> [ -f configfile | -o orgName ]"
    echo "      command: [ configorg | startorg | stoporg | startnode | stropnode | usage]"
}

if [ ! $FABRIC_BIN ]; then 
    logError "缺少环境变量: " "FABRIC_BIN"
    exit 1
fi 

COMMAND=$1
if [ ! $COMMAND ]; then 
    usage
    exit 1
fi 
shift

ORG_NAME=
CONF_FILE=

while getopts f:o:n: opt
do 
    case $opt in 
        f) CONF_FILE=$WORK_HOME/$OPTARG;;
        o) ORG_NAME=$OPTARG;;
        *) usage; exit 1;;
    esac 
done 

case $COMMAND in 
    configorg)
        if [ ! -f $CONF_FILE ]
        then
            logError "缺少配置文件:" "Org.conf" 
            exit 1
        fi 
        config 
        ;;
    startorg)
        if [ $ORG_NAME ]; then 
            if [ -d $WORK_HOME/$ORG_NAME ]; then 
                cd $WORK_HOME/$ORG_NAME 
            else 
                logError "组织不存在: " $ORG_NAME
                exit 1
            fi  
        fi 
        for node_name in $(ls . | grep peer); do
            sh ./$node_name/boot.sh 
            if [ $? -eq 0 ]; then 
                logSuccess "节点已启动: " $node_name
            fi 
        done 
        logSuccess "组织节点启动: " $ORG_NAME
        ;;
    startnode)
        if [ -f $WORK_HOME/boot.sh ]; then
            sh $WORK_HOME/boot.sh 
            if [ $? -eq 0]; then 
                logSuccess "节点已启动: " $node_name
            fi 
        fi 
        ;;
    stoporg)
        if [ $ORG_NAME ]; then 
            if [ -d $WORK_HOME/$ORG_NAME ]; then 
                cd $WORK_HOME/$ORG_NAME 
            else 
                logError "组织不存在: " $ORG_NAME
                exit 1
            fi  
        fi 
        for node_name in $(ls . | grep peer); do
            sh ./$node_name/stop.sh 
            if [ $? -eq 0 ]; then 
                logSuccess "节点已停止: " $node_name
            fi 
        done 
        logSuccess "组织节点停止: " $ORG_NAME
        ;;
    stopnode)
        if [ -f $WORK_HOME/stop.sh ]; then
            sh $WORK_HOME/stop.sh 
            if [ $? -eq 0]; then 
                logSuccess "节点已停止: " $node_name
            fi 
        fi 
        ;;
esac 

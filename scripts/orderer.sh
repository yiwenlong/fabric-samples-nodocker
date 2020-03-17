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
DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
WORK_HOME=$(pwd)

ORG_CONFIGTX_TEMPLATE_FILE=$DIR/template/configtx-orderer.yaml
CONFIGTX_COMMON_TEMPLATE_FILE=$DIR/template/configtx-common.yaml
ORDERER_TEMPLATE_FILE=$DIR/template/orderer.yaml

COMMAND_CRYPTOGEN=$FABRIC_BIN/cryptogen
COMMAND_CONFIGTXGEN=$FABRIC_BIN/configtxgen
COMMAND_ORDERER=$FABRIC_BIN/orderer

. $DIR/utils/log-utils.sh
. $DIR/utils/conf-utils.sh

function readConfOrgValue() {
    echo $(readConfValue $CONF_FILE 'org' $1)
}

function readConfNodeValue() {
    echo $(readConfValue $CONF_FILE $1 $2)
}

function configNode {
    node_name=$1
    logInfo "开始配置节点:" $node_name
    # 1. 从配置文件读取配置信息
    node_port=$(readConfNodeValue $node_name 'node.port')
    node_operations_port=$(readConfNodeValue $node_name 'node.operations.port')

    # 2. 创建节点配置目录
    org_name=$(readConfOrgValue 'org.name')
    org_home=$WORK_HOME/$org_name
    node_home=$org_home/$node_name
    if [ -d $node_home ]; then 
        rm -fr $node_home
    fi 
    mkdir -p $node_home
    cd $node_home
    logInfo "节点目录已创建:" $node_home

    # 3. 复制 MPS TLS 文件到节点工作目录
    org_domain=$(readConfOrgValue 'org.domain')
    cp -r $org_home/crypto-config/ordererOrganizations/$org_domain/orderers/$node_name.$org_domain/* $node_home
    logInfo "节点 msp 目录已生成:" $node_home/msp
    logInfo "节点 tls 目录已生成:" $node_home/tls

    # 4. 生成 orderer.yaml 文件
    org_mspid=$(readConfOrgValue 'org.mspid')
    node_domain=$node_name.$org_domain
    orderer_config_file=$node_home/orderer.yaml
    sed -e "s/<orderer.address>/${node_domain}/
    s/<orderer.port>/${node_port}/
    s/<org.mspid>/${org_mspid}/
    s/<orderer.operations.port>/${node_operations_port}/" $ORDERER_TEMPLATE_FILE > $orderer_config_file
    logInfo "节点启动文件已生成:" $orderer_config_file

    # 5. 生成 supervisor 的配置文件
    supervisor_process_name=fabric-$org_name-$node_name
    supervisor_conf_file_name=$supervisor_process_name.ini
    supervisor_conf_file=$node_home/$supervisor_conf_file_name
    echo "[program:$supervisor_process_name]" > $supervisor_conf_file
    echo "command=$COMMAND_ORDERER" >> $supervisor_conf_file
    echo "directory=${node_home}" >> $supervisor_conf_file
    echo "redirect_stderr=true" >> $supervisor_conf_file
    echo "stdout_logfile=${node_home}/orderer.log" >> $supervisor_conf_file
    echo "stdout_logfile_maxbytes=20MB" >> $supervisor_conf_file
    echo "stdout_logfile_backups=2 " >> $supervisor_conf_file
    logInfo "节点superviser配置文件已生成:" $supervisor_conf_file

    # 6. 生成启动节点的脚本
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
    logInfo "启动脚本已生成: " $boot_script_file

    # 7. 生成停止节点进程脚本
    stop_script_file=$node_home/stop.sh
    echo '#!/bin/bash' > $stop_script_file
    echo 'supervisorctl stop '$supervisor_process_name >> $stop_script_file
    echo 'rm /usr/local/etc/supervisor.d/'$supervisor_conf_file_name >> $stop_script_file
    echo 'supervisorctl remove '$supervisor_process_name >> $stop_script_file
    logInfo "停止脚本已生成: " $boot_script_file

    logSuccess "节点配置完成:" $node_name
}

function config {
    # 1. 从配置文件中读取配置信息
    org_name=$(readConfOrgValue 'org.name')
    org_mspid=$(readConfOrgValue 'org.mspid')
    org_domain=$(readConfOrgValue 'org.domain')
    org_node_count=$(readConfOrgValue 'org.node.count')

    # 2. 生成配置目录
    org_home=$WORK_HOME/$org_name
    if [ -d $org_home ]; then 
        rm -fr $org_home
    fi 
    mkdir -p $org_home
    cd $org_home
    logInfo "组织工作目录已创建:" $org_home

    # 3. 生成 MSP 配置文件
    msp_conf_file=$org_home/crypto-config.yaml
    echo 'OrdererOrgs:' > $msp_conf_file
    echo "  - Name: ${org_name}" >> $msp_conf_file
    echo "    Domain: ${org_domain}" >> $msp_conf_file
    echo "    Specs: " >> $msp_conf_file
    for (( i = 0; i < $org_node_count ; ++i)); do
        echo "      - Hostname: orderer${i}" >> $msp_conf_file
    done
    logInfo "Orderer 组织 MSP 配置文件已生成:" $msp_conf_file

    # 4. 生成 MSP 证书文件
    $COMMAND_CRYPTOGEN generate --config=$msp_conf_file
    if [ $? -eq 0 ]; then 
        logInfo "Orderer 组织 MSP 证书文件已生成: " $org_home/crypto-config
    else
        logError "Orderer 组织 MSP 证书文件生成失败！！！" 
    fi 

    # 5. 生成 configtx 的 orderer 组织的部分
    org_msp_dir=$org_home/crypto-config/ordererOrganizations/$org_domain/msp
    org_configtx_file=$org_home/configtx-org.yaml
    sed -e "s/<org.name>/${org_name}/
    s/<org.mspid>/${org_mspid}/
    s:<org.msp.dir>:${org_msp_dir}:" $ORG_CONFIGTX_TEMPLATE_FILE > $org_configtx_file

    # 6. 配置系统链创世块
    genesis_configtx_file=$org_home/configtx.yaml
    echo "Organizations:" > $genesis_configtx_file
    # 6.1. 写入 Orderer 组织信息
    cat $org_configtx_file >> $genesis_configtx_file
    # 6.2. 写入 Peer 组织信息
    _peerorgs=$(readConfNodeValue genesis genesis.peerorg.list)
    peerorgs=(${_peerorgs//,/ })
    for peer_org_name in ${peerorgs[@]}
    do
        cat $WORK_HOME/$peer_org_name/configtx-org.yaml >> $genesis_configtx_file
    done 
    # 6.3. 写入公共部分
    cat $CONFIGTX_COMMON_TEMPLATE_FILE >> $genesis_configtx_file
    # 6.4. 写入 Orderer 节点的地址信息
    for (( i = 0; i < $org_node_count ; ++i)); do
        node_name=orderer${i}
        node_address=$node_name.$org_domain
        node_port=$(readConfNodeValue $node_name node.port)
        echo "        - ${node_address}:${node_port}" >> $genesis_configtx_file
    done
    # 6.5. 写入创建 genesis 的 profile
    echo 'Profiles:
    SampleMultiNodeEtcdRaft:
        <<: *ChannelDefaults
        Capabilities:
            <<: *ChannelCapabilities
        Orderer:
            <<: *OrdererDefaults
            OrdererType: etcdraft
            EtcdRaft:
                Consenters:' >> $genesis_configtx_file
    for (( i = 0; i < $org_node_count ; ++i)); do
        node_name=orderer${i}
        node_home=$org_home/$node_name
        node_address=$node_name.$org_domain
        node_port=$(readConfNodeValue $node_name node.port)
        echo '                - Host: '${node_address}'
                  Port: '${node_port}'
                  ClientTLSCert: '${node_home}'/tls/server.crt
                  ServerTLSCert: '${node_home}'/tls/server.crt' >> $genesis_configtx_file
    done
    echo "            Addresses:" >> $genesis_configtx_file
    for (( i = 0; i < $org_node_count ; ++i)); do
        node_name=orderer${i}
        node_address=$node_name.$org_domain
        node_port=$(readConfNodeValue $node_name node.port)
        echo "                - ${node_address}:${node_port}" >> $genesis_configtx_file
    done
    echo '            Organizations:
            - *'${org_name}'
            Capabilities:
                <<: *OrdererCapabilities
        Application:
            <<: *ApplicationDefaults
            Organizations:
            - <<: *'${org_name}'
        Consortiums:
            SampleConsortium:
                Organizations:' >> $genesis_configtx_file
    for peer_org_name in ${peerorgs[@]}
    do
        echo "                - *${peer_org_name}" >> $genesis_configtx_file
    done 
    logInfo "系统链配置文件已生成: " $genesis_configtx_file

    # 7. 配置 Orderer 节点
    for (( i = 0; i < $org_node_count ; ++i)); do
        configNode orderer$i
    done
    logInfo "组织节点已配置完成"

    # 8. 生成系统链创世区块，复制到节点目录下
    sys_channel_name=$(readConfOrgValue org.sys.channel.name)
    sys_channel_genesis_file=$org_home/genesis.block

    $COMMAND_CONFIGTXGEN \
        -profile SampleMultiNodeEtcdRaft \
        -channelID $sys_channel_name \
        -outputBlock $sys_channel_genesis_file \
        -configPath $org_home

    for (( i = 0; i < $org_node_count ; ++i)); do
        cp $org_home/genesis.block $org_home/orderer$i/
    done

    logSuccess "组织配置已完成:" $org_name
}


function usage {
    exit 0
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
            logError "缺少配置文件:" "Orderer.conf" 
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
        for node_name in $(ls . | grep orderer); do
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
        for node_name in $(ls . | grep orderer); do
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
    *) usage; exit 1;;
esac
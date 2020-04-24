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
SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
WORK_HOME=$(pwd)

TMP_CORE="$SCRIPT_DIR/template/core.yaml"

EXTERNAL_BUILDER_NAME=my_external_builder
EXTERNAL_BUILDER_PATH=my_external_builder

. "$SCRIPT_DIR/utils/log-utils.sh"
. "$SCRIPT_DIR/utils/conf-utils.sh"
. "$SCRIPT_DIR/utils/file-utils.sh"

function usage() {
    echo "usage"
}

while getopts f:d:n: opt
do
  case $opt in
    f) CONF_FILE=$(absolutefile "$OPTARG" "$WORK_HOME");;
    d) DEST_DIR=$(absolutefile "$OPTARG" "$WORK_HOME")
      mkdir -p "$DEST_DIR";;
    n) NODE_NAME="$OPTARG";;
    *) usage; exit 1;;
  esac
done

checkfileexist "$CONF_FILE"
checkdirexist "$DEST_DIR"
if [ ! "$NODE_NAME" ]; then
    logError "Missing node name" "-n node_name"
fi

org_mspid="$(readConfValue "$CONF_FILE" org org.mspid)"
org_domain="$(readConfValue "$CONF_FILE" org org.domain)"

node_domain="$NODE_NAME.$org_domain"
node_port="$(readConfValue "$CONF_FILE" "$NODE_NAME" node.port)"
node_chaincode_port="$(readConfValue "$CONF_FILE" "$NODE_NAME" node.chaincode.port)"
node_operations_port="$(readConfValue "$CONF_FILE" "$NODE_NAME" node.operations.port)"
node_couchdb_address="$(readConfValue "$CONF_FILE" "$NODE_NAME" node.couchdb.address)"
node_couchdb_user="$(readConfValue "$CONF_FILE" "$NODE_NAME" node.couchdb.user)"
node_couchdb_pwd="$(readConfValue "$CONF_FILE" "$NODE_NAME" node.couchdb.pwd)"

gossip_node="$(readConfValue "$CONF_FILE" "$NODE_NAME" node.gossip)"
gossip_node_port="$(readConfValue "$CONF_FILE" "$gossip_node" node.port)"

core_file="$DEST_DIR/core.yaml"
sed -e "s/<peer.name>/${NODE_NAME}/
s/<peer.mspid>/${org_mspid}/
s/<peer.address>/${node_domain}:${node_port}/
s/<peer.domain>/${node_domain}/
s/<peer.gossip.address>/${gossip_node}.${org_domain}:${gossip_node_port}/
s/<peer.operations.port>/${node_operations_port}/
s/<peer.couchdb.address>/${node_couchdb_address}/
s/<peer.couchdb.username>/${node_couchdb_user}/
s/<peer.couchdb.password>/${node_couchdb_pwd}/
s/<peer.chaincode.builder.path>/${EXTERNAL_BUILDER_NAME}/
s/<peer.chaincode.builder.name>/${EXTERNAL_BUILDER_PATH}/
s/<peer.chaincode.address>/${node_domain}:${node_chaincode_port}/" "$TMP_CORE" > "$core_file"
logSuccess "Node config file generated" "$core_file"
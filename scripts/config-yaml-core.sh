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

# shellcheck source=utils/log-utils.sh
. "$SCRIPT_DIR/utils/log-utils.sh"
# shellcheck source=utils/conf-utils.sh
. "$SCRIPT_DIR/utils/conf-utils.sh"
# shellcheck source=utils/file-utils.sh
. "$SCRIPT_DIR/utils/file-utils.sh"

function usage() {
    echo "Usage:"
    echo "  config-yaml-core.sh -f org_conf.ini -d node_home -n node_name"
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
    exit 1
fi

org_mspid="$(readConfValue "$CONF_FILE" org org.mspid)"
org_domain="$(readConfValue "$CONF_FILE" org org.domain)"

node_domain="$NODE_NAME.$org_domain"
state_db_type="goleveldb"
couchdb_conf=$(readConfValue "$CONF_FILE" "$NODE_NAME" "node.couchdb")
if [ -n "$couchdb_conf" ]; then
  state_db_type="Couchdb"
  node_couchdb_address=$(readConfValue "$CONF_FILE" "$couchdb_conf" "couchdb.address")
  node_couchdb_user=$(readConfValue "$CONF_FILE" "$couchdb_conf" "couchdb.user")
  node_couchdb_pwd=$(readConfValue "$CONF_FILE" "$couchdb_conf" "couchdb.passwd")
fi

node_listen=$(readConfValue "$CONF_FILE" "$NODE_NAME" node.listen)
node_operations_listen=$(readConfValue "$CONF_FILE" "$NODE_NAME" node.operations.listen)
node_gossip_bootstrap=$(readConfValue "$CONF_FILE" "$NODE_NAME" node.gossip.bootstrap)
node_chaincode_listen=$(readConfValue "$CONF_FILE" "$NODE_NAME" node.chaincode.listen)

logInfo "Node domain:" "$node_domain"
logInfo "Node listen address:" "$node_listen"
logInfo "Node chaincode listen address:" "$node_chaincode_listen"
logInfo "Node operations listen address:" "$node_operations_listen"
logInfo "Node gossip bootstrap address:" "$node_gossip_bootstrap"

core_file="$DEST_DIR/core.yaml"
sed -e "s/<peer.name>/${NODE_NAME}/
s/<peer.mspid>/${org_mspid}/
s/<peer.address>/${node_listen}/
s/<peer.gossip.address>/${node_gossip_bootstrap}/
s/<peer.chaincode.address>/${node_chaincode_listen}/
s/<peer.operations.address>/${node_operations_listen}/
s/<peer.state.database>/${state_db_type}/
s/<peer.couchdb.address>/${node_couchdb_address}/
s/<peer.couchdb.username>/${node_couchdb_user}/
s/<peer.couchdb.password>/${node_couchdb_pwd}/
s/<peer.chaincode.builder.path>/${EXTERNAL_BUILDER_NAME}/
s/<peer.chaincode.builder.name>/${EXTERNAL_BUILDER_PATH}/" "$TMP_CORE" > "$core_file"
logSuccess "Node config file generated" "$core_file"
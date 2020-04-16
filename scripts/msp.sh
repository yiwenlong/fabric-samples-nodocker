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

CMD_CRYPTOGEN="$FABRIC_BIN/cryptogen"
TMP_PEER="$SCRIPT_DIR/template/crypto-config-peer.yaml"

. "$SCRIPT_DIR/utils/log-utils.sh"
. "$SCRIPT_DIR/utils/conf-utils.sh"
. "$SCRIPT_DIR/utils/file-utils.sh"

function usage() {
    echo "usage"
}

while getopts f:t:d: opt
do
  case $opt in
    f) CONF_FILE=$(absolutefile "$OPTARG" "$WORK_HOME")
      checkfileexist "$CONF_FILE";;
    t) TYPE=$OPTARG ;;
    d) DEST_DIR=$(absolutefile "$OPTARG" "$WORK_HOME")
      mkdir -p "$DEST_DIR";;
    *) usage; exit 1;;
  esac
done

org_name=$(readConfValue "$CONF_FILE" org org.name)
org_domain=$(readConfValue "$CONF_FILE" org org.domain)
org_node_count=$(readConfValue "$CONF_FILE" org org.node.count)
org_user_count=$(readConfValue "$CONF_FILE" org org.user.count)

msp_conf_file="$DEST_DIR/crypto-config.yaml"

if [ "$TYPE" == "orderer" ]; then
  echo "OrdererOrgs:" > "$msp_conf_file"
  echo "  - Name: ${org_name}" >> "$msp_conf_file"
  echo "    Domain: ${org_domain}" >> "$msp_conf_file"
  echo "    Specs: " >> "$msp_conf_file"
  for (( i = 0; i < "$org_node_count" ; ++i)); do
    echo "      - Hostname: orderer${i}" >> "$msp_conf_file"
  done
elif [ "$TYPE" == "peer" ]; then
  sed -e "s/<org.name>/${org_name}/
  s/<org.domain>/${org_domain}/
  s/<org.peer.count>/${org_node_count}/
  s/<org.peer.user.count>/${org_user_count}/" "$TMP_PEER" > "$msp_conf_file"
else
  usage
  exit 1
fi
logInfo "Organization MSP config file generated:" "$msp_conf_file"

msg=$($CMD_CRYPTOGEN generate --config="$msp_conf_file")
if [ $? -eq 0 ]; then
  logSuccess "Organization MSP certificate files generated:" "$msp_conf_file"
else
  logError "Organization MSP certificate file generate failed！！！" "$msg"
  exit $?
fi
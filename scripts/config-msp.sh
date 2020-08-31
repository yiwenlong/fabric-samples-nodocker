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

# shellcheck source=utils/file-utils.sh
. "$SCRIPT_DIR/utils/file-utils.sh"
# shellcheck disable=SC1090
. "$SCRIPT_DIR/utils/conf-utils.sh"

function usage() {
    echo "Usage"
    echo "  config-msp.sh -t [peer|orderer] -d org_home -f org_conf.ini"
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
  {
    echo "OrdererOrgs:"
    echo "  - Name: ${org_name}"
    echo "    Domain: ${org_domain}"
    echo "    Specs: "
  } > "$msp_conf_file"
  for (( i = 0; i < "$org_node_count" ; ++i)); do
    echo "      - Hostname: orderer${i}" >> "$msp_conf_file"
  done
elif [ "$TYPE" == "peer" ]; then
  {
    echo "PeerOrgs:"
    echo "  - Name: ${org_name}"
    echo "    Domain: ${org_domain}"
    echo "    EnableNodeOUs: true"
    echo "    Template:"
    echo "      Count: ${org_node_count}"
    echo "    Users:"
    echo "      Count: ${org_user_count}"
  } > "$msp_conf_file"
else
  usage
  exit 1
fi
echo "Organization MSP config file generated:" "$msp_conf_file"

if msg=$($CMD_CRYPTOGEN generate --config="$msp_conf_file"); then
  echo "Organization MSP certificate files generated:" "$msp_conf_file"
else
  echo "Organization MSP certificate file generate failed！！！" "$msg"
  exit $?
fi
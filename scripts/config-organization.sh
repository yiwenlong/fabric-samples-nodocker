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

export ORG_NAME="org.name"
export ORG_MSPID="org.mspid"
export ORG_DOMAIN="org.domain"
export ORG_COUNT_PEERS="org.peers"
export ORG_COUNT_ORDERERS="org.peers"

. "$DIR/utils/log-utils.sh"
. "$DIR/utils/conf-utils.sh"
. "$DIR/utils/file-utils.sh"

function readConfOrgValue() {
  readConfValue "$CONF_FILE" org "$1"; echo
}

function readConfPeerValue() {
  readConfValue "$CONF_FILE" "$1" "$2"; echo
}

# Config organization with following steps:
# 1. Read config file.
# 2. Create a directory for this organization.
# 3. Copy this config file into the organization directory.
# 4. Config all peer nodes of this organization.
# 5. Config all orderer nodes of this organization.
function config {
  # 1. Read config file.
  local o_name=$(readConfOrgValue "$ORG_NAME")
  local o_mspid=$(readConfOrgValue "$ORG_MSPID")
  local o_domain=$(readConfOrgValue "$ORG_DOMAIN")
  local op_count=$(readConfOrgValue "$ORG_COUNT_PEERS")
  local oo_count=$(readConfOrgValue "$ORG_COUNT_ORDERERS")

  logInfo "Start config organization: " "$o_name"
  logInfo "-----------------------------------------------------"
  logInfo "MSPID:\t\t\t" "$o_mspid"
  logInfo "Domain:\t\t\t" "$o_domain"
  logInfo "Peer node count:\t" "$op_count"
  logInfo "Orderer node count:\t" "$oo_count"
  logInfo "-----------------------------------------------------"

   # 2. Create a directory for this organization.
  local o_home="$OUTPUT_DIR/$o_name"
  if [ -d "$o_home" ]; then
    logError "Working directory already exists!! $o_home"
    exit 1
  fi
  mkdir -p "$o_home" && cd "$o_home" || exit
  logInfo "Organization config directory created:" "$o_home"

  # 3. Copy this config file into the organization directory.
  cp "$CONF_FILE" "$o_home/conf.ini"

  # 4. Config all peer nodes of this organization.
  for (( i = 0; i < "$op_count" ; ++i)); do
    logInfo "Start config peer$i"
  done

   # 5. Config all orderer nodes of this organization.
  for (( i = 0; i < "$op_count" ; ++i)); do
    logInfo "Start config orderer$i"
  done
}

function usage {
  echo "USAGE:"
  echo "config-organization.sh <-f conf.ini> [-d output-directory]"
  exit 1
}

while getopts f:d: opt
do
  case $opt in
    f) CONF_FILE=$(absolutefile "$OPTARG" "$WORK_HOME")
      checkfileexist "$CONF_FILE";;
    d) OUTPUT_DIR=$(absolutefile "$OPTARG" "$WORK_HOME")
      checkdirexist "$OUTPUT_DIR";;
    *) usage; exit 1;;
  esac
done

if [ ! -d "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$WORK_HOME"
fi

config
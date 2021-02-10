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

export NODE_MSP="node.msp"
export NODE_TLS="node.tls"
export NODE_DAEMON="node.daemon"

DAEMON_SUPPORT_SCRIPT="$DIR/daemon-support/config-daemon.sh"
DEFAULT_NODE_PROCESS_PRE="FABRIC-NODOCKER"

DEFAULT_COMMAND_PEER="peer node start"
DEFAULT_COMMAND_ORDERER="orderer"

. "$DIR/utils/log-utils.sh"
. "$DIR/utils/conf-utils.sh"
. "$DIR/utils/file-utils.sh"

# Create node directory with given organization dir and node name
# $1 organization directory path.
# $2 node name
function createNodeDirectory {
  local n_home="$1"
  if [ -d "$n_home" ]; then
    logError "Node directory already exists!!" "$n_home"
    exit 1
  fi
  if [ -f "$n_home" ]; then
    logError "Node directory path is file!!" "$n_home"
    exit 1
  fi
  mkdir -p "$n_home" && cd "$n_home" || exit
  logSuccess "Node directory created:\t" "$n_home"
}

# Config node daemon scripts: boot.sh & stop.sh
# $1 organization name
# $2 node name
# $3 node directory
# $4 node boot command
function configNodeDaemon {
  local o_name=$1
  local n_name=$2
  local n_home=$3
  local n_command=$4
  d_type=$(readConfPeerValue "$n_name" "$NODE_DAEMON")
  np_name="$DEFAULT_NODE_PROCESS_PRE-$o_name-$n_name"
  if ! "$DAEMON_SUPPORT_SCRIPT" -d "$d_type" -n "$np_name" -h "$n_home" -c "$n_command"; then
    exit $?
  fi
  logSuccess "Node daemon script generated." "$o_name"
}

function configPeerNode {
  local o_name=$1
  local o_domain=$2
  local o_mspid=$3
  local o_home=$4
  local n_name=$5
  local n_home="$o_home/$n_name"
  logInfo "--------------------------- $n_name ---------------------------"
  logInfo "Start config node: " "$o_name.$n_name"
  logInfo "MspID:\t\t\t" "$o_mspid"
  logInfo "Domain: \t\t" "$n_name.$o_domain"
  createNodeDirectory "$n_home"
  configNodeDaemon "$o_name" "$n_name" "$n_home" "$DEFAULT_COMMAND_PEER"
  logInfo "--------------------------- $n_name ---------------------------"
}

function configOrdererNode {
  local o_name=$1
  local o_domain=$2
  local o_mspid=$3
  local o_home=$4
  local n_name=$5
  local n_home="$o_home/$n_name"
  logInfo "--------------------------- $n_name ---------------------------"
  logInfo "Start config node: " "$o_name.$n_name"
  logInfo "MspID:\t\t\t" "$o_mspid"
  logInfo "Domain: \t\t" "$n_name.$o_domain"
  createNodeDirectory "$n_home"
  configNodeDaemon "$o_name" "$n_name" "$n_home" "$DEFAULT_COMMAND_ORDERER"
  logInfo "--------------------------- $n_name ---------------------------"
}

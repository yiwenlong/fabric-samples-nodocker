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

export FABRIC_BIN=$(cd "$DIR"/../../fabric-bin/darwin && pwd)
export SCRIPT_PATH=$(cd "$DIR"/../../scripts && pwd)

. "$SCRIPT_PATH"/utils/log-utils.sh

function networksetup() {
  startPeerOrg
  startOrdererOrg
}

function startPeerOrg() {
  logInfo "Config organization:" Org1
  "$SCRIPT_PATH"/peer.sh configorg -f Org1.conf
  logInfo "Start organization nodes:" Org1
  "$SCRIPT_PATH"/peer.sh startorg -o"" Org1
  logSuccess "Organization started:" Org1
}

function startOrdererOrg() {
  logInfo "Config orderer:" Orderer
  "$SCRIPT_PATH"/orderer.sh configorg -f Orderer.conf
  echo "Start orderer:" Orderer
  "$SCRIPT_PATH"/orderer.sh startorg -o Orderer
  logSuccess "Orderer started:" Orderer
}

function networkdown() {
  logInfo "Down organization:" Org1
  "$SCRIPT_PATH"/peer.sh stoporg -o Org1
  logInfo "Clean organization:" Org1
  rm -fr "$DIR"/Org1
  logInfo "Down orderer:" Orderer
  "$SCRIPT_PATH"/orderer.sh stoporg -o Orderer
  logInfo "Clean orderer:" Orderer
  rm -fr "$DIR"/Orderer
  logSuccess "Network stoped!"
}

function usage() {
  echo "USAGE"
  exit 0
}

COMMAND=$1
case $COMMAND in 
  up)
    networksetup ;;
  down)
    networkdown ;;
  *) usage;;
esac
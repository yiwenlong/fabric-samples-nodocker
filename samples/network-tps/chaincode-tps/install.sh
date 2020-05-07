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
export FABRIC_BIN=$(cd "$DIR"/../../../fabric-bin/darwin && pwd)
export SCRIPT_PATH=$(cd "$DIR"/../../../scripts && pwd)
export FABRIC_CFG_PATH=$(cd "$DIR"/../Org1/peer0 && pwd)

CHANNEL_HOME=$(cd "$DIR"/../channel-mychannel/mychannel && pwd)

. "$SCRIPT_PATH"/utils/log-utils.sh

logInfo "Package chaincode:" tps
"$SCRIPT_PATH"/chaincode.sh package -f cc-tps.ini
logInfo "Install chaincode:" "tps -> org1.peer0"
"$SCRIPT_PATH"/chaincode.sh install -h chaincode-home-cc-tps -c "$CHANNEL_HOME"/Org1-peer0-mychannel-conf
#logInfo "Install chaincode:" "tps -> org1.peer0"
#"$SCRIPT_PATH"/chaincode.sh install -h chaincode-home-cc-tps -c "$CHANNEL_HOME"/Org1-peer1-mychannel-conf
#logInfo "Approve chaincode:" "tps"
#"$SCRIPT_PATH"/chaincode.sh approve -h chaincode-home-cc-tps -c "$CHANNEL_HOME"/Org1-peer0-mychannel-conf
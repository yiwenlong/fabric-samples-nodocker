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
export FABRIC_BIN=$(cd "$DIR"/../../../binaries/darwin/fabric && pwd)
export SCRIPT_PATH=$(cd "$DIR"/../../../scripts && pwd)
export FABRIC_CFG_PATH=$(cd "$DIR"/../Org1/peer0 && pwd)

CHANNEL_HOME=$(cd "$DIR"/../channel-mychannel/mychannel && pwd)

# shellcheck source=utils/log-utils.sh
. "$SCRIPT_PATH/utils/log-utils.sh"

logInfo "Package chaincode:" tps
if ! "$SCRIPT_PATH"/chaincode.sh package -f cc-tps.ini; then
  exit $?
fi

logInfo "Install chaincode:" "tps -> org1.peer0"
if ! "$SCRIPT_PATH"/chaincode.sh install -h chaincode-home-cc-tps -c "$CHANNEL_HOME"/Org1-peer0-mychannel-conf; then
  exit $?
fi

logInfo "Install chaincode:" "tps -> org1.peer0"
if ! "$SCRIPT_PATH"/chaincode.sh install -h chaincode-home-cc-tps -c "$CHANNEL_HOME"/Org1-peer1-mychannel-conf; then
  exit $?
fi

logInfo "Approve chaincode:" "tps"
if ! "$SCRIPT_PATH"/chaincode.sh approve -h chaincode-home-cc-tps -c "$CHANNEL_HOME"/Org1-peer0-mychannel-conf; then
  exit $?
fi

logInfo "Config chaincode server boot scripts:" "tps"
if ! "$SCRIPT_PATH"/chaincode.sh configChaincodeServer -h chaincode-home-cc-tps -c "$CHANNEL_HOME"/Org1-peer0-mychannel-conf; then
  exit $?
fi

logInfo "Starting chaincode server:" "tps"
if ! ./chaincode-home-cc-tps/boot.sh; then
  exit $?
fi

logInfo "Commit chaincode define:" "tps"
if ! "$SCRIPT_PATH"/chaincode.sh commit -h chaincode-home-cc-tps -c "$CHANNEL_HOME"/Org1-peer0-mychannel-conf; then
  exit $?
fi

logInfo "Init chaincode:" "tps"
if ! "$SCRIPT_PATH"/chaincode.sh invoke -i -n tps -c "$CHANNEL_HOME"/Org1-peer0-mychannel-conf -v '{"Args":["Init",""]}'; then
  exit $?
fi

sleep 3
logInfo "Invoke chaincode:" "tps"
if ! "$SCRIPT_PATH"/chaincode.sh invoke -n tps -c "$CHANNEL_HOME"/Org1-peer0-mychannel-conf -v '{"Args":["put","whoareyou","fabric-samples-nodocker"]}'; then
  exit $?
fi

sleep 3
logInfo "Query chaincode on peer0:" "tps"
if ! "$SCRIPT_PATH"/chaincode.sh query -n tps -c "$CHANNEL_HOME"/Org1-peer0-mychannel-conf -v '{"Args":["get","whoareyou"]}'; then
  exit $?
fi
logInfo "Query chaincode on peer1:" "tps"
if ! "$SCRIPT_PATH"/chaincode.sh query -n tps -c "$CHANNEL_HOME"/Org1-peer1-mychannel-conf -v '{"Args":["get","whoareyou"]}'; then
  exit $?
fi

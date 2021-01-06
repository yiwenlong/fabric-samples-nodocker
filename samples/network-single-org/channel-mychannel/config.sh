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
arch=$(uname -s|tr '[:upper:]' '[:lower:]')
export FABRIC_BIN=$(cd "$DIR"/../../../binaries/"$arch"/fabric && pwd)
export SCRIPT_PATH=$(cd "$DIR"/../../../scripts && pwd)
export FABRIC_CFG_PATH=$(cd "$DIR"/../Org1/peer0 && pwd)

. "$SCRIPT_PATH"/utils/log-utils.sh

logInfo "Config channel:" mychannel
"$SCRIPT_PATH"/channel.sh config -f mychannel.ini

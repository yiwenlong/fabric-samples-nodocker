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

. "$DIR/config-node.sh"

function configPeer {
  local o_name=$1
  local o_domain=$2
  local o_mspid=$3
  local n_name=$4
  logInfo "Start config node: " "$o_name.$n_name"
  logInfo "--------------------------- $n_name ---------------------------"
  logInfo "MspID:\t\t\t" "$o_mspid"
  logInfo "Domain: \t\t" "$n_name.$o_domain"
  logInfo "--------------------------- $n_name ---------------------------"
}
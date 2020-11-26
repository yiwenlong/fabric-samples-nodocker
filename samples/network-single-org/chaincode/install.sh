#!/usr/bin/env bash
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
PEER_CMD="../../../binaries/darwin/fabric/peer"
org1_crypto_base_dir=$(cd "$SCRIPT_DIR/../Org1/crypto-config/peerOrganizations/org1.example.fnodocker.icu" && pwd)
orderer_crypto_base_dir=$(cd "$SCRIPT_DIR/../Orderer/crypto-config/ordererOrganizations/example.fnodocker.icu" && pwd)
orderer_tlsca="$orderer_crypto_base_dir/tlsca/tlsca.example.fnodocker.icu-cert.pem"
orderer_address="orderer0.example.fnodocker.icu:7050"

cc_path="github.com/yiwenlong/chaincode-examples/abac/src/abac"
cc_name=abac
cc_version=1.0
cc_language=golang
ch_name=mychannel
cc_args='{"Args":["init","a","100","b","200"]}'
cc_policy="AND ('Org1MSP.peer')"

export CORE_PEER_MSPCONFIGPATH="$org1_crypto_base_dir/users/Admin@org1.example.fnodocker.icu/msp"
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE="$org1_crypto_base_dir/tlsca/tlsca.org1.example.fnodocker.icu-cert.pem"
export CORE_PEER_TLS_ENABLE=true
export FABRIC_CFG_PATH="../Org1/peer0"

echo "Start install chaincode on peer0.org1.example.fnodocker.icu"
export CORE_PEER_ADDRESS=peer0.org1.example.fnodocker.icu:7051
$PEER_CMD chaincode install \
  -n "$cc_name" \
  -v "$cc_version" \
  -l "$cc_language" \
  -p "$cc_path"

$PEER_CMD chaincode list --installed

echo "Start install chaincode on peer0.org1.example.fnodocker.icu"
export CORE_PEER_ADDRESS=peer1.org1.example.fnodocker.icu:8051
$PEER_CMD chaincode install \
  -n "$cc_name" \
  -v "$cc_version" \
  -l "$cc_language" \
  -p "$cc_path"

$PEER_CMD chaincode list --installed

$PEER_CMD chaincode instantiate \
  -o "$orderer_address"\
  -C "$ch_name" \
  -n "$cc_name" \
  -l "$cc_language" \
  -v "$cc_version" \
  -c "$cc_args" \
  -P "$cc_policy" \
  --tls true \
  --cafile "$orderer_tlsca"

sleep 5

$PEER_CMD chaincode list --instantiated -C "$ch_name"
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

orderer_crypto_base_dir=$(cd "$SCRIPT_DIR/../Orderer/crypto-config/ordererOrganizations/example.fnodocker.icu" && pwd)
orderer_tlsca="$orderer_crypto_base_dir/tlsca/tlsca.example.fnodocker.icu-cert.pem"
orderer_address="orderer0.example.fnodocker.icu:7050"

org1_crypto_base_dir=$(cd "$SCRIPT_DIR/../Org1/crypto-config/peerOrganizations/org1.example.fnodocker.icu" && pwd)
org1_tlsca="$org1_crypto_base_dir/tlsca/tlsca.org1.example.fnodocker.icu-cert.pem"
peer_address=peer0.org1.example.fnodocker.icu:7051

export CORE_PEER_MSPCONFIGPATH="$org1_crypto_base_dir/users/Admin@org1.example.fnodocker.icu/msp"
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE="$org1_tlsca"
export CORE_PEER_TLS_ENABLE=true
export FABRIC_CFG_PATH="../Org1/peer0"

cc_name=abac
ch_name=mychannel

export CORE_PEER_ADDRESS=peer0.org1.example.fnodocker.icu:7051
echo "Query a:"
$PEER_CMD chaincode query -C "$ch_name" -n "$cc_name" -c '{"Args":["query","a"]}'
echo "Query b:"
$PEER_CMD chaincode query -C "$ch_name" -n "$cc_name" -c '{"Args":["query","b"]}'

echo "invoke a -> b 10"
$PEER_CMD chaincode invoke \
  -o "$orderer_address" \
  --tls true \
  --cafile "$orderer_tlsca" \
  -C "$ch_name" \
  -n "$cc_name" \
  --peerAddresses "$peer_address" \
  --tlsRootCertFiles "$org1_tlsca" \
  -c '{"Args":["invoke","a","b","10"]}'

sleep 3
echo "Query a:"
$PEER_CMD chaincode query -C "$ch_name" -n "$cc_name" -c '{"Args":["query","a"]}'
echo "Query b:"
$PEER_CMD chaincode query -C "$ch_name" -n "$cc_name" -c '{"Args":["query","b"]}'

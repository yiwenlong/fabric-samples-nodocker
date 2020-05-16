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

function download() {
    local TAR_FILE=$1
    local URL=$2
    echo "===> Downloading: " "${URL}"
    wget "${URL}" || rc=$?
    tar xvzf "${TAR_FILE}" || rc=$?
    rm "${TAR_FILE}"
    if [ -n "$rc" ]; then
        echo "==> There was an error downloading the binary file."
        return 22
    else
        echo "==> Done."
    fi
}

ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')")

rm -fr "$(pwd)/build/*"
mkdir -p "$(pwd)/build/chaincode"

cd ./build/

MARCH=$(uname -m)
FABRIC_VERSION=2.0.1
FABRIC_TAG=${MARCH}-${FABRIC_VERSION}
TAR_FILE=hyperledger-fabric-${ARCH}-${FABRIC_VERSION}.tar.gz
echo "===> Downloading version ${FABRIC_TAG} platform specific fabric binaries"
download "${TAR_FILE}" "https://github.com/hyperledger/fabric/releases/download/v${FABRIC_VERSION}/${TAR_FILE}"
if [ $? -eq 22 ]; then
    echo
    echo "------> ${FABRIC_TAG} platform specific fabric binary is not available to download <----"
    echo
    exit
fi

cd ./chaincode/
CHAINCODE_TPS_VERSION=1.0
CHAINCODE_TPS_BINARY_FILE=tps-${ARCH}-${CHAINCODE_TPS_VERSION}.tar.gz
download "${CHAINCODE_TPS_BINARY_FILE}" "https://github.com/yiwenlong/chaincode-examples/releases/download/tps-${CHAINCODE_TPS_VERSION}/${CHAINCODE_TPS_BINARY_FILE}"
if [ $? -eq 22 ]; then
    echo
    echo "------> ${ARCH} platform specific tps binary is not available to download <----"
    echo
    exit
fi
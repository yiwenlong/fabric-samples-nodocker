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

# build chaincode
mkdir -p "$(pwd)/build/chaincode"
rm -fr "$(pwd)/build/chaincode/*"
export GOBIN="$(pwd)/build/chaincode"
go install github.com/yiwenlong/fabric-samples-nodocker/chaincode/tps

function download() {
    local BINARY_FILE=$1
    local URL=$2
    echo "===> Downloading: " "${URL}"
    wget "${URL}" || rc=$?
    tar xvzf "${BINARY_FILE}" || rc=$?
    rm "${BINARY_FILE}"
    if [ -n "$rc" ]; then
        echo "==> There was an error downloading the binary file."
        return 22
    else
        echo "==> Done."
    fi
}
cd ./build/
VERSION=2.0.1
MARCH=$(uname -m)
FABRIC_TAG=${MARCH}-${VERSION}
ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')")
BINARY_FILE=hyperledger-fabric-${ARCH}-${VERSION}.tar.gz
echo "===> Downloading version ${FABRIC_TAG} platform specific fabric binaries"
download "${BINARY_FILE}" "https://github.com/hyperledger/fabric/releases/download/v${VERSION}/${BINARY_FILE}"
if [ $? -eq 22 ]; then
    echo
    echo "------> ${FABRIC_TAG} platform specific fabric binary is not available to download <----"
    echo
    exit
fi
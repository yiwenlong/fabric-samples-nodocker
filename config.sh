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
BINARIES_DIR="$DIR/binaries/"

FABRIC_VERSION="2.0.1"
TPS_VERSION="1.0.0"

function download() {
    local TAR_FILE=$1
    local URL=$2
    echo "===> Downloading: " "${URL}"
    curl -OL "${URL}" || rc=$?
}

function download_fabric_binaries() {
  local PLATFORM="$1"
  local ARCH="$PLATFORM-amd64"
  local FABRIC_VERSION="$2"
  local TAR_FILE="hyperledger-fabric-${ARCH}-${FABRIC_VERSION}.tar.gz"
  download "${TAR_FILE}" "https://github.com/hyperledger/fabric/releases/download/v${FABRIC_VERSION}/${TAR_FILE}"
  if [ $? -eq 22 ]; then
    echo
    echo "------> ${ARCH} platform specific fabric binary is not available to download <----"
    echo
    exit
  fi
  tar xvzf "${TAR_FILE}" || rc=$?
  if [ -n "$rc" ]; then
    echo "==> There was an error downloading the binary file."
    return 22
  else
      echo "==> Done."
  fi
  mkdir -p "$BINARIES_DIR/$PLATFORM/fabric/"
  cp "$DIR/bin/"* "$BINARIES_DIR/$PLATFORM/fabric"
  rm -fr "$DIR/bin/" "$DIR/config/"
  rm -f "$TAR_FILE"
}

function download_tps_binary() {
  local PLATFORM="$1"
  local ARCH="$PLATFORM-amd64"
  local TPS_VERSION="$2"
  local TAR_FILE="tps-${ARCH}-${TPS_VERSION}.tar.gz"
  download "${TAR_FILE}" "https://github.com/yiwenlong/chaincode-examples/releases/download/tps-v${TPS_VERSION}/${TAR_FILE}"

  if [ $? -eq 22 ]; then
    echo
    echo "------> ${ARCH} platform specific tps binary is not available to download <----"
    echo
    exit
  fi

  tar xvzf "${TAR_FILE}" || rc=$?
  if [ -n "$rc" ]; then
    echo "==> There was an error downloading the binary file."
    return 22
  else
    echo "==> Done."
  fi

  mkdir -p "$BINARIES_DIR/$PLATFORM/chaincode/"
  cp "$DIR/tps"* "$BINARIES_DIR/$PLATFORM/chaincode"
  rm -f "$TAR_FILE"
  rm -fr "$DIR/tps"*
}

for platform in "linux" "darwin" "windows"; do
  download_fabric_binaries "$platform" "$FABRIC_VERSION"
  download_tps_binary "$platform" "$TPS_VERSION"
done
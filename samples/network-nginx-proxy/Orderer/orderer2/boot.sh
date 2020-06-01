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
BOOT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
export FABRIC_CFG_PATH=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

function checkSuccess() {
  if [[ $? != 0 ]]; then
      exit $?
  fi
}

dst_file="/usr/local/etc/supervisor.d/FABRIC-NODOCKER-Orderer-orderer2.ini"
if [ -f "$dst_file" ]; then
  rm "$dst_file"
fi

if [ ! -d "/usr/local/etc/supervisor.d/" ]; then
  mkdir -p "/usr/local/etc/supervisor.d/"
fi

echo "[program:FABRIC-NODOCKER-Orderer-orderer2]" > "$dst_file"
echo "command=$BOOT_DIR/orderer" >> "$dst_file"
echo "directory=$BOOT_DIR" >> "$dst_file"
echo "redirect_stderr=true" >> "$dst_file"
echo "stdout_logfile=$BOOT_DIR/FABRIC-NODOCKER-Orderer-orderer2.log" >> "$dst_file"
echo "Supervisor config file generate:" "$dst_file"

supervisorctl update
echo Staring: "FABRIC-NODOCKER-Orderer-orderer2"
sleep 3
supervisorctl status | grep "FABRIC-NODOCKER-Orderer-orderer2"

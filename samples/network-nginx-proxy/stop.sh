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
export SUPERVISOR_CONF_SUFFIX="ini"
# If you don't set SUPERVISOR_CONFD_DIR, set a default value.
if [ -z "$SUPERVISOR_CONFD_DIR" ]; then
  arch=$(uname -s|tr '[:upper:]' '[:lower:]')
  if [ "$arch" == "darwin" ]; then
    # macos
    export SUPERVISOR_CONFD_DIR="/usr/local/etc/supervisor.d"
  elif [ "$arch" == "linux" ]; then
    # centos Linux
    if hostnamectl | grep "Ubuntu" ; then
      export SUPERVISOR_CONFD_DIR="/etc/supervisor/conf.d"
      export SUPERVISOR_CONF_SUFFIX="conf"
    elif < /etc/system-release grep CentOS ; then
      export SUPERVISOR_CONFD_DIR="/etc/supervisord.d"
    fi
  fi
fi
./Org1/peer0/stop.sh
./Org1/peer1/stop.sh
./Orderer/orderer0/stop.sh
./Orderer/orderer1/stop.sh
./Orderer/orderer2/stop.sh

supervisorctl status
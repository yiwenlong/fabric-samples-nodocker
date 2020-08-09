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
DEFAULT_CONF_SUFFIX="ini"
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
      DEFAULT_CONF_SUFFIX="conf"
    elif < /etc/system-release grep CentOS ; then
      export SUPERVISOR_CONFD_DIR="/etc/supervisord.d"
    fi
  fi
fi
supervisorctl stop _process_name_
supervisorctl remove _process_name_
rm "$SUPERVISOR_CONFD_DIR/_process_name_.$DEFAULT_CONF_SUFFIX"
supervisorctl status

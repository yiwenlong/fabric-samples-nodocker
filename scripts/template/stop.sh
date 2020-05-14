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

arch=$(uname -s|tr '[:upper:]' '[:lower:]')
if [ "$arch" == "darwin" ]; then
  supervisor_conf_dir="/usr/local/etc/supervisor.d"
elif [ "$arch" == "linux" ]; then
  supervisor_conf_dir="/etc/supervisor.d"
else
  echo "System operation not support."
  eixt
fi

supervisorctl stop _supervisor_conf_file_name_
rm "$supervisor_conf_dir/_supervisor_conf_file_name_.ini"
supervisorctl remove _supervisor_conf_file_name_
supervisorctl status

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

# shellcheck source=utils/log-utils.sh
. "$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)/utils/log-utils.sh"
# shellcheck source=utils/file-utils.sh
. "$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)/utils/file-utils.sh"

function usage() {
    echo "Usage:"
    echo "  config-supervisor.sh -n process_name -h work_home -c command"
}

while getopts n:h:c: opt
do
  case $opt in
    n) process_name="$OPTARG" ;;
    h) work_home="$OPTARG" ;;
    c) command="$OPTARG";;
    *) usage; exit 1;;
  esac
done

checkdirexist "$work_home"
dst_file="$work_home/$process_name.ini"

echo "[program:$process_name]" > "$dst_file"
echo "command=$command" >> "$dst_file"
echo "directory=${work_home}" >> "$dst_file"
echo "redirect_stderr=true" >> "$dst_file"
echo "stdout_logfile=${work_home}/$process_name.log" >> "$dst_file"
logSuccess "Supervisor config file generate:" "$dst_file"
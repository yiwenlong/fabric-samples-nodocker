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

SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

TMP_BOOT="$SCRIPT_DIR/launchd/boot.sh"
TMP_STOP="$SCRIPT_DIR/launchd/stop.sh"

while getopts n:h:c: opt
do
  case $opt in
    n) process_name=$OPTARG ;;
    h) working_home=$OPTARG ;;
    c) command=$OPTARG ;;
    *) usage; exit 1;;
  esac
done

if [ ! -d "$working_home" ]; then
  echo "Home directory not found: $working_home"
  exit $?
fi

boot_script_file=$working_home/boot.sh
sed -e "s/_process_name_/${process_name}/
s/_process_command_/${command}/" "$TMP_BOOT" > "$boot_script_file"
chmod +x "$boot_script_file"
echo -e "\033[Daemon boot script generated:\033[0m $boot_script_file"

stop_script_file=$working_home/stop.sh
sed -e "s/_process_name_/${process_name}/" "$TMP_STOP" > "$stop_script_file"
chmod +x "$stop_script_file"
echo -e "\033[Daemon stop script generated:\033[0m $stop_script_file"
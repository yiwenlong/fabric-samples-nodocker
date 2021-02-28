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

DEFAULT_DAEMON_TYPE="nodaemon"

while getopts n:h:c:d: opt
do
  case $opt in
    n) process_name=$OPTARG ;;
    h) working_home=$OPTARG ;;
    c) command=$OPTARG ;;
    d) daemon_type=$OPTARG;;
    *) usage; exit 1;;
  esac
done

if [ ! "$daemon_type" ]; then
   daemon_type="$DEFAULT_DAEMON_TYPE"
fi

if [ ! -d "$working_home" ]; then
  echo "Home directory not found: $working_home"
  exit $?
fi

TMP_BOOT="$SCRIPT_DIR/$daemon_type/boot.sh"
TMP_STOP="$SCRIPT_DIR/$daemon_type/stop.sh"

boot_script_file=$working_home/boot.sh
sed -e "s/_process_name_/${process_name}/
s/_process_command_/${command}/" "$TMP_BOOT" > "$boot_script_file"
chmod +x "$boot_script_file"
echo -e "Daemon boot script generated: $boot_script_file"

stop_script_file=$working_home/stop.sh
sed -e "s/_process_name_/${process_name}/" "$TMP_STOP" > "$stop_script_file"
chmod +x "$stop_script_file"
echo -e "Daemon stop script generated: $stop_script_file"
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

dst_file="$HOME/Library/LaunchAgents/_process_name_.plist"
if [ -f "$dst_file" ]; then
  rm "$dst_file"
fi

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  echo '<plist version="1.0">'
  echo '  <dict>'
  echo '    <key>KeepAlive</key>'
  echo '    <dict>'
  echo '      <key>SuccessfulExit</key>'
  echo '      <false/>'
  echo '    </dict>'
  echo '    <key>WorkingDirectory</key>'
  echo "    <string>$BOOT_DIR</string>"
  echo '    <key>EnvironmentVariables</key>'
  echo '    <dict>'
  echo '      <key>FABRIC_CFG_PATH</key>'
  echo "      <string>$BOOT_DIR</string>"
  echo '    </dict>'
  echo '    <key>Label</key>'
  echo '    <string>_process_name_</string>'
  echo '    <key>StandardOutPath</key>'
  echo "    <string>$BOOT_DIR/_process_name_.log</string>"
  echo '    <key>StandardErrorPath</key>'
  echo "    <string>$BOOT_DIR/_process_name_.log</string>"
  echo '    <key>ProgramArguments</key>'
  echo '    <array>'
} > "$dst_file"

command="$BOOT_DIR/_process_command_"
for arg in $command; do
  echo "      <string>$arg</string>" >> "$dst_file"
done
{
  echo '    </array>'
  echo '  </dict>'
  echo '</plist>'
} >> "$dst_file"

echo Staring: "_process_name_"
launchctl load -w "$dst_file"
sleep 1
launchctl list | grep _process_name_
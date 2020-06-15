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

TMP_COUCHDB_CONFIG="$SCRIPT_DIR/template/couchdb-config.ini"
TMP_COUCHDB_VM="$SCRIPT_DIR/template/couchdb-vm.args"
TMP_BOOT="$SCRIPT_DIR/template/couchdb-boot.sh"
TMP_STOP="$SCRIPT_DIR/template/stop.sh"

DEFAULT_CONF_SUFFIX="ini"

# shellcheck source=utils/log-utils.sh
. "$SCRIPT_DIR/utils/log-utils.sh"

COUCHDB_CMD=$(command -v couchdb)
if [ -z "$COUCHDB_CMD" ]; then
    logError "couchdb not found"
    exit 1
fi

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

work_home="/Users/yiwenlong/couchdb-demo"
chttp_port=5985
http_port=5986
admin_user="admin"
admin_passwd="adminpw"
couchdb_name="demo-couchdb-process"

couchdb_config_dir="$work_home/conf"
mkdir -p "$couchdb_config_dir"

couchdb_config_file="$couchdb_config_dir/config.ini"
sed -e "s:<couchdb-home>:${work_home}:
    s/<couchdb-chttp-port>/${chttp_port}/
    s/<couchdb-http-port>/${http_port}/
    s/<couchdb-admin-user>/${admin_user}/
    s/<couchdb-admin-passwd>/${admin_passwd}/" "$TMP_COUCHDB_CONFIG" > "$couchdb_config_file"

couchdb_vm_file="$couchdb_config_dir/vm.args"
sed -e "s/<couchdb-name>/${couchdb_name}/" "$TMP_COUCHDB_VM" > "$couchdb_vm_file"

boot_script_file="$work_home/boot.sh"
supervisor_conf_file_name="demo-couchdb-process"
sed -e "s/_supervisor_conf_file_name_/${supervisor_conf_file_name}/
    s/_suffix_/${DEFAULT_CONF_SUFFIX}/
    s:_supervisor_conf_dir_:${SUPERVISOR_CONFD_DIR}:
    s:_command_:${COUCHDB_CMD}:
    s:_couchdb_config_file_:${couchdb_config_file}:
    s:_vm_args_file_:${couchdb_vm_file}:" "$TMP_BOOT" > "$boot_script_file"
chmod +x "$boot_script_file"
logSuccess "Couchdb boot script generated: " "$boot_script_file"

stop_script_file="$work_home/stop.sh"
sed -e "s/_supervisor_conf_file_name_/${supervisor_conf_file_name}/
    s/_suffix_/${DEFAULT_CONF_SUFFIX}/
    s:_supervisor_conf_dir_:${SUPERVISOR_CONFD_DIR}:" "$TMP_STOP" > "$stop_script_file"
chmod +x "$stop_script_file"
logSuccess "Couchdb stop script generated: " "$stop_script_file"


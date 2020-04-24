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

function readConfValue() {
    CONF_FILE=$1
    KEY=$2
    SUB_KEY=$3
    if [ "$SUB_KEY" ]
    then 
        echo $(awk -F '=' '/\['$KEY'\]/{a=1}a==1&&$1~/'$SUB_KEY'/{print $2;exit}' $CONF_FILE)
    else
        echo $(awk -F '=' '/'$KEY'/{print $2;exit}' $CONF_FILE)
    fi 
}
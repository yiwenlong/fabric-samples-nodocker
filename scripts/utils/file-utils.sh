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

"$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)/log-utils.sh"

function checkfileexist {
    if [ ! -f "$1" ]; then
        logError "File not found:" $1
        exit 1
    fi
}

function checkdirexist {
    if [ ! -d "$1" ]; then
        logError "Directory not found:" $1
        exit 1
    fi
}

function absolutefile() {
    file=$1
    relative_dir=$2
    if [ "${file:0:1}" = "/" ]; then
        echo "$file"
    else 
        if [[ $relative_dir =~ /$ ]]; then 
            echo "$relative_dir$file"
        else 
            echo "$relative_dir/$file"
        fi 
    fi 
}
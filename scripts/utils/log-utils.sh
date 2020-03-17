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
INFO_COLOR=34m
ERROR_COLOR=31m
SUCCESS_COLOR=32m

function logInfo {
    TAG=$1
    MESSAGE=$2
    echo -e "\033[$INFO_COLOR$TAG\033[0m $MESSAGE"
}

function logError {
    TAG=$1
    MESSAGE=$2
    echo -e "\033[$ERROR_COLOR$TAG\033[0m $MESSAGE"
}

function logSuccess {
    TAG=$1
    MESSAGE=$2
    echo -e "\033[$SUCCESS_COLOR$TAG\033[0m $MESSAGE"
}
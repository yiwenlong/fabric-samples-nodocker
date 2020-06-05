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

rm -fr ./Orderer/*/etcdraft/
rm -fr ./Orderer/*/file-ledger/
rm -fr ./Orderer/*/FABRIC-NODOCKER-Orderer-*.log
rm -fr ./Orderer/*/orderer
rm -fr ./Org1/*/data/
rm -fr ./Org1/*/FABRIC-NODOCKER-Org1-*.log
rm -fr ./Org1/*/peer

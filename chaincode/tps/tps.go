//
// Copyright 2020 Yiwenlong(wlong.yi#gmail.com)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package main

import (
	"fmt"
	"os"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	pb "github.com/hyperledger/fabric-protos-go/peer"
)

// Tps Chaincode implementation
type Tps struct {
}

func (t *Tps) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("Tps Init")
	return shim.Success(nil)
}

func (t *Tps) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fcn, params := stub.GetFunctionAndParameters()
	fmt.Println("Invoke()", fcn, params)
	if fcn == "put" {
		stub.PutState(params[0], []byte(params[1]))
		return shim.Success(nil)
	} else if fcn == "get" {
		data, err := stub.GetState(params[0])
		if err != nil {
			return shim.Error(err.Error())
		}
		return shim.Success(data)
	}
	return shim.Error("error")
}

func main() {
	ccid := os.Args[1]
	address := os.Args[2]
	server := &shim.ChaincodeServer{
		CCID:    ccid,
		Address: address,
		CC:      new(Tps),
		TLSProps: shim.TLSProperties{
			Disabled: true,
		},
	}
	err := server.Start()
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}

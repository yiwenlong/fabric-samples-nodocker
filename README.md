## Fabric samples nodocker - tools to deploy fabric network without docker

中文介绍[文档](https://www.jianshu.com/p/1f9b051d1e1d)

**Note:** You can run this script tools on Linux/MaxOS. 

## Start

### Prerequisites

##### Install homebrew

```shell
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

##### Install wget & jq & supervisor

```shell
brew install wget
brew install jq
brew install supervisor
```

##### Start supervisor service

```
brew services start supervisor
```

##### Checkout this respository

```shell
git clone https://github.com/yiwenlong/fabric-samples-nodocker.git
```

#### Using the Single org test network

##### Config binary files

```sh
cd $fabric-samples-nodocker
./config.sh
```

##### Bring up the test network

```shell
cd $fabric-samples-nodocker/samples/network-tps
./network up
```

##### Bring up the test network

```shell
cd $fabric-samples-nodocker/samples/network-tps
./network down
```


## Fabric samples nodocker - tools to deploy fabric network without docker

**Note:** The scripts is currently only applicable to maxOS x operation system.

## Start

### Prerequisites

##### Install homebrew

```shell
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

##### Install wget

```shell
brew install wget
```

##### Install jq

```shell
brew install jq
```

##### Install supervisor

```shell
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


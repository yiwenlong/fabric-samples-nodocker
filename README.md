## Fabric samples nodocker - tools to deploy fabric network without docker

中文介绍[文档](https://www.jianshu.com/p/1f9b051d1e1d)

**Note:** You can run this script tools on Linux/MaxOS. 

## Start

### Prerequisites

##### Install & bring up supervisor service

```shell
# MacOS
brew install supervisor
brew services start supervisor
# CentOS
yum install supervisor
supervisord
# Ubuntu
apt install supervisor
supervisord

# Check your supervisor
supervicosrctl status
```

##### Checkout this respository

```shell
git clone https://github.com/yiwenlong/fabric-samples-nodocker.git
```

##### Config environment

```sh
cd $fabric-samples-nodocker
./config.sh
# Config your supervisor config dir. 
# MacOS
export SUPERVISOR_CONFD_DIR=/usr/local/etc/supervisor.d
# CentOS
export SUPERVISOR_CONFD_DIR=/etc/supervisord.d
# Ubuntu
export SUPERVISOR_CONFD_DIR=/etc/supervisor/conf.d  
```

#### Using the Single org test network

##### Add the following to the host file(/etc/hosts)

```shell
127.0.0.1 	peer0.org1.example.com
127.0.0.1 	peer1.org1.example.com
127.0.0.1 	orderer0.example.com
127.0.0.1 	orderer1.example.com
127.0.0.1 	orderer2.example.com
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


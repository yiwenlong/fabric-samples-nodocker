## Fabric samples nodocker - tools to deploy fabric network without docker

中文介绍[文档](https://www.jianshu.com/p/1f9b051d1e1d)

**Note:** You can run this script tools on Linux/MaxOS. 

## Start

> Notice: If you run this script on ubuntu, please add sudo before the command.

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
service supervisor start

# Check your supervisor
supervicosrctl status
```

More information about [supervisor](http://supervisord.org/).

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

##### Bring up the test network

```shell
cd $fabric-samples-nodocker/samples/network-single-org
./network up
```

##### Bring up the test network

```shell
cd $fabric-samples-nodocker/samples/network-single-org
./network down
```


# 脱离 Docker 部署 Fabric 网络
## 使用说明

* 当前是根据 Fabric 1.4.9 版本开发，理论上可以直接支持 Fabric 1.4.x 下的任意版本。
* 由于 Fabric 1.4.x chaincode 是运行在 Docker 容器中的，所以本脚本只做到了支持节点进程本地化，未对 chaincode 进行修改。

### 环境准备

* Docker 环境，用于运行 `chaincode`。

* Go 语言环境，配置 `GOPATH` 环境变量。


### 执行配置脚本

```shell
cd $fabric-samples-nodocker
# 下载 fabric 相关的二进制程序文件
# 下载 chaincode 源码
# 下载必要的 docker 镜像
# 由于执行配置脚本时，会自动拉取 hyperledger/fabric-ccenv 和 hyperledger/fabric-baseos 镜像，建议国内用户配置国内的 docker 镜像源。
./config.sh
```

### 一键启动网络

#### 1、一键启动测试网络

```shell
cd $fabric-samples-nodocker/samples/network-single-org
./network up
```

#### 2、关闭并清理网络

```shell
./network down
```

### 手动启动网络

#### 1、配置网络

```shell
cd $fabric-samples-nodocker/samples/network-single-org
./network config
```

#### 2、启动网络

```shell
# 启动所有配置的节点
./network start

# 如果需要只启动单独的节点，可以执行节点目录下的 boot.sh 脚本。
# 例如启动 Org1 的 peer0 节点
cd $fabric-samples-nodocker/samples/network-single-org/Org1/peer0
./boot.sh

# 如果不需要使用守护进程，可以进入节点目录，直接通过节点程序启动
# 例如启动 Org1 的 peer0 节点
cd $fabric-samples-nodocker/samples/network-single-org/Org1/peer0
./peer node start
# 例如启动 Orderer 的 orderer0 节点
cd $fabric-samples-nodocker/samples/network-single-org/Orderer/orderer0
./orderer
```

#### 3、关闭并清理网络

```shell
./network down
```


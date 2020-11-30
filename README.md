# 脱离 Docker 部署 Fabric 网络
## 使用说明

* 当前是根据 Fabric 1.4.9 版本开发，理论上可以直接支持 Fabric 1.4.x 下的任意版本。
* 由于 Fabric 1.4.x chaincode 是运行在 Docker 容器中的，所以本脚本只做到了支持节点进程本地化，未对 chaincode 进行修改。

### 环境准备

* Docker 环境，用于运行 chaincode。

* supervisor 用于管理节点进程，也可以不使用。MacOS 下可以支持 launchd 进行进程管理。

* 下载 chaincode 代码到 `$GOPATH/src/github.com/yiwenlong`

  ```shell
  cd $GOPATH/src/github.com/yiwenlong
  git clone https://github.com/yiwenlong/chaincode-examples.git
  ```

### 一键启动网络

> 一键自动启动网络需要 supervisor 或者 launchd(MacOS) 的支持。如果不想使用守护进程管理，可以通过手动启动网络，同样方便快捷。

#### 1、自动下载节点程序

```shell
cd $fabric-samples-nodocker
./config.sh
```

#### 2、一键启动测试网络

```shell
cd $fabric-samples-nodocker/samples/network-single-org
./network up
```

#### 3、关闭网络

```shell
./network down
```

### 手动启动网络

> 手动启动网络可以不需要守护进程支持。

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


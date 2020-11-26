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

### 启动网络

#### 自动下载节点程序

```shell
cd $fabric-samples-nodocker
./config.sh
```

#### 一键启动测试网络

```shell
cd $fabric-samples-nodocker/samples/network-single-org
./network up
```

#### 关闭网络

```shell
./network down
```


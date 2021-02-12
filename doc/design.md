## 设计理解
此脚本基于作者对 Hyperledger Fabric 项目的以下架构理解构建起来的：
* Hyperledger Fabric 联盟链能够链接不同的组织，在组织之间构建可信的链接。
* 组织是联盟链中的基本单位。
* 组织之间，使用 Channel 链接起来。
* Chaincode 代表了组织间业务往来的协议。
  ![部署图](./images/deploy.png "部署图")
## 部署基本步骤
因此部署 Hyperledger Fabric 应该遵循以下步骤:
* 构建 Hyperledger Fabric 的组织，其中最关键的是组织的 MSP。
* 构建系统 Channel，在构建系统 Channel 时需要组织相关的信息。
* 部署用户 Channel 和 Chaincode。
## 组织构建步骤
* 确定组织基本信息。
* 构建 CA 架构。
* 配置组织下的 peer 和 orderer 节点集群。
## 系统 Channel 构建步骤
* 确定参与系统 Channel 的组织和 Channel 下的权限信息。
* 确定参与排序的 orderer 节点。
* 生成系统 Channel 创世区块。
## 用户 Channel 构建步骤
* 确定参与用户 Channel 的组织和 Channel 下的权限信息。
* 生成用户 Channel 的配置交易。
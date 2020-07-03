| Node Name        | Listen Port | Nginx proxy port       |
| ---------------- | ----------- | ---------------------- |
| Org1.peer0       | 7051        | 17051    ==>    7051   |
| Org1.peer1       | 8051        | 18051    ==>    8051   |
| Orderer.orderer0 | 17050       | 7050     ==>     7150 |
| Orderer.orderer1 | 18050       | 8050     ==>     8150 |
| Orderer.orderer2 | 19050       | 9050     ==>     9150 |

##### Add the following to the host file(/etc/hosts)

```shell
sudo vim /etc/hosts
```

```shell
127.0.0.1 	peer0.org1.example.com
127.0.0.1 	peer1.org1.example.com
127.0.0.1 	orderer0.example.com
127.0.0.1 	orderer1.example.com
127.0.0.1 	orderer2.example.com
```


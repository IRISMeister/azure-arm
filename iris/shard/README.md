# iris shard
## リソースグループ
指定したリソースグループ下に下記が作成される。

|NAME|	TYPE|	LOCATION|備考|
|--|--|--|--|
|clientnic	|Network interface|Japan East|client,10.0.1.10固定|
|clientvm	|Virtual machine|Japan East|client|
|clientvm_OsDisk_1_xxx	|Disk|Japan East|client|
|irisAvailabilitySet	|Availability set|Japan East|clientvm,data-mastervm0,datavm0,datavm1|
|jumpboxnic	|Network interface|Japan East||
|jumpboxpublicIp	|Public IP address|Japan East|公開用IP|
|jumpboxvm	|Virtual machine|Japan East||
|jumpboxvm_OsDisk_1_xxx	|Disk|Japan East||
|data-masternic0	|Network interface|Japan East|DATAノード #1(MASTER)|
|data-mastervm0	|Virtual machine|Japan East|DATAノード #1(MASTER)|
|data-mastervm0_disk2_xxx	|Disk|Japan East|DATAノード #1(MASTER)|
|data-mastervm0_disk3_xxx	|Disk|Japan East|DATAノード #1(MASTER)|
|data-mastervm0_OSDisk	|Disk|Japan East|DATAノード #1(MASTER)|
|ngw	|NAT gateway	|Japan East|NAT-GW|
|ngw-pubip	|Public IP address	|Japan East|NAT-GW用のパブリックIP|
|datanic0	|Network interface|Japan East|DATAノード #2|
|datavm0	|Virtual machine|Japan East|DATAノード #2|
|datavm0_disk2_xxx	|Disk|Japan East|DATAノード #2|
|datavm0_disk3_xxx	|Disk|Japan East|DATAノード #2|
|datavm0_OSDisk	|Disk|Japan East|DATAノード #2|
|datanic1	|Network interface|Japan East|DATAノード #3|
|datavm1	|Virtual machine|Japan East|DATAノード #3|
|datavm1_disk2_xxx	|Disk|Japan East|DATAノード #3|
|datavm1_disk3_xxx	|Disk|Japan East|DATAノード #3|
|datavm1_OSDisk	|Disk|Japan East|DATAノード #3|
|vnet	|Virtual network|Japan East|DATAノード #3|

## デプロイ後のアクセス
### IRIS管理ポータル  

IRISサーバはプライベートネットワーク上のVMにデプロイされる。正常に動作した場合、10分ほどで完了。  
![1](https://raw.githubusercontent.com/IRISMeister/doc-images/main/iris-azure-arm/deployment-shard.png)

プライベートネットワーク上のVMアクセス用にJumpBoxがデプロイされるので、SSHポートフォワーディングを使用して管理ポータルにアクセスします。bash端末(Windows上のGit bashなどでも可)を3個開き、下記を実行します。

```bash
ssh -i [秘密鍵] -L [local-port]:[VM名]]:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
[adminUsername]@[domainName].japaneast.cloudapp.azure.com

例) 
```bash
端末1
ssh -i my-azure-keypair.pem -L 8888:data-mastervm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
irismeister@my-irishost-1.japaneast.cloudapp.azure.com
端末2
ssh -i my-azure-keypair.pem -L 8889:datavm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
irismeister@my-irishost-1.japaneast.cloudapp.azure.com
端末3
ssh -i my-azure-keypair.pem -L 8890:datavm1:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
irismeister@my-irishost-1.japaneast.cloudapp.azure.com
```
データノード#1(MASTER)  
http://localhost:8888/csp/sys/UtilHome.csp  
データノード#2  
http://localhost:8889/csp/sys/UtilHome.csp  
データノード#3  
http://localhost:8890/csp/sys/UtilHome.csp

## 補足事項
### サンプルデータのロード
### SimpleMover
```bash
$ ssh -i my-azure-keypair.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-irishost-1.japaneast.cloudapp.azure.com -A
irismeister@jumpboxvm:~$ ssh clientvm
irismeister@clientvm:~$ ./green.sh
Writing log into: fromCSV.log
Time elapsed:       0s. Read:  0.0000%; Written:  0.0000%
Starting Reading Threads: 2
    ・
    ・
    ・
Time elapsed:     121s. Read: 99.9999%; Written: 99.9999%; Success Rate:  100.00%; Error Rate:    0.00% Insertion Rate:   11925.8761 row/sec Total new rows:    1445285
TOTAL Time between:  120.00s and  121.19s;       Insertion Rate is between:   11925.8761 and   12044.1420 row/sec
irismeister@clientvm:~$
```
#### JDBC
```bash
irismeister@clientvm:~$ javac JDBCSample.java
irismeister@clientvm:~$ java -cp .:intersystems-jdbc-3.2.0.jar JDBCSample
```

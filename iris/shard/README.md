# iris shard
## リソースグループ
指定したリソースグループ下に下記が作成されます。

|NAME|	TYPE|	LOCATION|備考|
|--|--|--|--|
|clientnic	|Network interface|Japan East|client,10.0.1.10固定|
|clientvm	|Virtual machine|Japan East|client|
|clientvm_OsDisk_1_xxx	|Disk|Japan East|client|
|irisAvailabilitySet	|Availability set|Japan East|clientvm,msvm0,slvm0,slvm1|
|jumpboxnic	|Network interface|Japan East||
|jumpboxpublicIp	|Public IP address|Japan East|公開用IP|
|jumpboxvm	|Virtual machine|Japan East||
|jumpboxvm_OsDisk_1_xxx	|Disk|Japan East||
|msnic0	|Network interface|Japan East|DATAノード #1(MASTER)|
|msvm0	|Virtual machine|Japan East|DATAノード #1(MASTER)|
|msvm0_disk2_xxx	|Disk|Japan East|DATAノード #1(MASTER)|
|msvm0_disk3_xxx	|Disk|Japan East|DATAノード #1(MASTER)|
|msvm0_OSDisk	|Disk|Japan East|DATAノード #1(MASTER)|
|ngw	|NAT gateway	|Japan East|NAT-GW|
|ngw-pubip	|Public IP address	|Japan East|NAT-GW用のパブリックIP|
|datanic0	|Network interface|Japan East|DATAノード #2|
|slvm0	|Virtual machine|Japan East|DATAノード #2|
|slvm0_disk2_xxx	|Disk|Japan East|DATAノード #2|
|slvm0_disk3_xxx	|Disk|Japan East|DATAノード #2|
|slvm0_OSDisk	|Disk|Japan East|DATAノード #2|
|datanic1	|Network interface|Japan East|DATAノード #3|
|slvm1	|Virtual machine|Japan East|DATAノード #3|
|slvm1_disk2_xxx	|Disk|Japan East|DATAノード #3|
|slvm1_disk3_xxx	|Disk|Japan East|DATAノード #3|
|slvm1_OSDisk	|Disk|Japan East|DATAノード #3|
|vnet	|Virtual network|Japan East|DATAノード #3|

## デプロイ後のアクセス
### IRIS管理ポータル  

IRISサーバはプライベートネットワーク上のVMにデプロイされます。正常に動作した場合、10分ほどで完了します。  
![1](https://raw.githubusercontent.com/IRISMeister/doc-images/main/iris-azure-arm/deployment-shard.png)

プライベートネットワーク上のVMアクセス用にJumpBoxがデプロイされるので、SSHポートフォワーディングを使用して管理ポータルにアクセスします。bash端末(Windows上のGit bashなどでも可)を3個開き、下記を実行しください。

```bash
ssh -i [秘密鍵] -L [local-port]:[VM名]]:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null [adminUsername]@[domainName].japaneast.cloudapp.azure.com

例) 
```bash
端末1
ssh -i my-azure-keypair.pem -L 8888:msvm0:80 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-irishost-1.japaneast.cloudapp.azure.com
端末2
ssh -i my-azure-keypair.pem -L 8889:slvm0:80 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-irishost-1.japaneast.cloudapp.azure.com
端末3
ssh -i my-azure-keypair.pem -L 8890:slvm1:80 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-irishost-1.japaneast.cloudapp.azure.com
```
データノード#1(MASTER)  
http://localhost:8888/csp/sys/UtilHome.csp  , http://localhost:8888/csp/bin/Systems/Module.cxw
データノード#2  
http://localhost:8889/csp/sys/UtilHome.csp  
データノード#3  
http://localhost:8890/csp/sys/UtilHome.csp

## 補足事項
### サンプルデータのロード
#### SimpleMoverの使用例

[ニューヨーク市のタクシー運航データのオープンデータ](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page)をロードします。

```
ssh msvm0
iris session iris -U%SYS "##class(Silent.Installer).LoadCSV()"

iris session iris -U%SYS 
%SYS> d ##class(Silent.Installer).LoadCSV(,"/var/tmp/data/10M.csv")
```
#### JDBCの使用例
ごく簡単な[JDBCアクセス](JDBCSample.java)の例です。
```bash
irismeister@clientvm:~$ javac JDBCSample.java
irismeister@clientvm:~$ java -cp .:intersystems-jdbc-3.2.0.jar JDBCSample
```

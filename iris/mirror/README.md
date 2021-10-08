# iris mirror
WIP

## リソースグループ
指定したリソースグループ下に下記が作成される。

|NAME|	TYPE|	LOCATION|備考|
|--|--|--|--|
|arbiternic	|Network interface|Japan East|Arbiter,10.0.1.10固定|
|arbitervm	|Virtual machine|Japan East|Arbiter|
|arbitervm_OsDisk_1_xxx	|Disk|Japan East|Arbiter|
|ilb	|Load balancer	|Japan East|IRISミラー用の内部LB|
|irisAvailabilitySet	|Availability set|Japan East|arbitervm,msvm0,slvm0|
|jumpboxnic	|Network interface|Japan East||
|jumpboxpublicIp	|Public IP address|Japan East|公開用IP|
|jumpboxvm	|Virtual machine|Japan East||
|jumpboxvm_OsDisk_1_xxx	|Disk|Japan East||
|msnic0	|Network interface|Japan East|プライマリ,10.0.1.11固定|
|msvm0	|Virtual machine|Japan East|プライマリ|
|msvm0_disk2_xxx	|Disk|Japan East|プライマリ|
|msvm0_disk3_xxx	|Disk|Japan East|プライマリ|
|msvm0_OSDisk	|Disk|Japan East|プライマリ|
|ngw	|NAT gateway	|Japan East|NAT-GW|
|ngw-pubip	|Public IP address	|Japan East|NAT-GW用のパブリックIP|
|slnic0	|Network interface|Japan East|バックアップ,10.0.1.12固定|
|slvm0	|Virtual machine|Japan East|バックアップ|
|slvm0_disk2_xxx	|Disk|Japan East|バックアップ|
|slvm0_disk3_xxx	|Disk|Japan East|バックアップ|
|slvm0_OSDisk	|Disk|Japan East|バックアップ|
|vnet	|Virtual network|Japan East|バックアップ|

## デプロイ後のアクセス
### IRIS管理ポータル  

IRISサーバはプライベートネットワーク上のVMにデプロイされる。正常に動作した場合、15分ほどで完了。  
![1](https://raw.githubusercontent.com/IRISMeister/doc-images/main/iris-azure-arm/deployment.png)

プライベートネットワーク上のVMアクセス用にJumpBoxがデプロイされるので、SSHポートフォワーディングを使用してIRISにアクセスする。
bash端末((Windows上のGit bashなどでも可)を2個開き、下記を実行する。

端末1
```bash
ssh -L 8888:msvm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
[adminUsername]@[domainName].japaneast.cloudapp.azure.com
```

端末2
```bash
ssh -L 8889:slvm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
[adminUsername]@[domainName].japaneast.cloudapp.azure.com
```

例) 
端末1
```bash
ssh -L 8888:msvm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
irismeister@my-irishost-1.japaneast.cloudapp.azure.com
irismeister@jumpboxvm:~$
```
端末2
```bash
ssh -L 8889:slvm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
irismeister@my-irishost-1.japaneast.cloudapp.azure.com
irismeister@jumpboxvm:~$
```
プライマリサーバ  
http://localhost:8888/csp/sys/UtilHome.csp  
バックアップサーバ  
http://localhost:8889/csp/sys/UtilHome.csp

## 補足

### 障害ドメイン
日本リージョンには、障害ドメイン(Fault Domain)は2個しかない。  
https://github.com/MicrosoftDocs/azure-docs/blob/master/includes/managed-disks-common-fault-domain-region-list.md

より可用性の高い[Availability Zones](https://azure.microsoft.com/ja-jp/updates/general-availability-azure-availability-zones-in-japan-east/)の使用を検討しても良いかもしれない。同期ミラーリング使用時はサーバ間のネットワーク遅延の拡大(それに伴うパフォーマンスへの悪影響)に留意が必要。

### HealthProbe用のエンドポイント
Probe対象は、下記で表示されるmsvm0,slvm0のPrivateIPAddresses。
```bash
$ az vm list-ip-addresses --resource-group $rg --output table
VirtualMachine    PrivateIPAddresses    PublicIPAddresses
----------------  --------------------  -------------------
arbitervm         10.0.1.10
jumpboxvm         10.0.0.4              52.185.171.9
msvm0             10.0.1.11
slvm0             10.0.1.12
```

エンドポイントの動作確認のため、arbitervmから下記を実行する。  

プライマリメンバに接続した場合の応答
```bash
irismeister@arbitervm:~$  echo `curl http://msvm0:52773/csp/bin/mirror_status.cxw -s`
SUCCESS
```
バックアップメンバに接続した場合の応答
```bash
irismeister@arbitervm:~$  echo `curl http://slvm0:52773/csp/bin/mirror_status.cxw -s`
FAILED
```

### NAT-GW
ミラー構成用に内部Load Balancerをデプロイしている。下記URLの挙動(プライベートIPしかもたないVMがInternetにアウトバウンド接続できない状態。AWSと同じ挙動)となるため、NAT-GWを構成している。  
https://docs.microsoft.com/ja-jp/azure/load-balancer/load-balancer-outbound-connections#how-does-default-snat-work

> Standard 内部 Load Balancer を使用する場合、SNAT のために一時 IP アドレスは使用されません。 この機能は、既定でセキュリティをサポートします。 この機能により、リソースによって使用されるすべての IP アドレスが構成可能になり、予約できるようになります。 Standard 内部 Load Balancer を使用するときに、インターネットへのアウトバウンド接続を実現するには、次を構成します。
> - インスタンス レベルのパブリック IP アドレス
> - VNet NAT
> - アウトバウンド規則が構成された Standard パブリック ロード バランサーへのバックエンド インスタンス。

NAT-GW構成後のpublic ipは、NAT-GWのOutbound IPに一致するようになる。
```bash
irismeister@msvm0:~$ curl https://ipinfo.io/ip
23.102.69.138
```
```bash
irismeister@slvm0:~$ curl https://ipinfo.io/ip
23.102.69.138
```
### 内部LB動作確認
常にミラーのプライマリメンバに接続が行われる事を確認するために、JDBCアプリケーションをLBに対して接続する。
> このJDBCアプリケーションは、同期対象に**なっていない**テーブルを作成、更新する

```bash
irismeister@jumpboxvm:~$ ssh irismeister@arbitervm
irismeister@arbitervm:~$ sudo su -
root@arbitervm:~# cd /var/lib/waagent/custom-script/download/0
root@arbitervm:/var/lib/waagent/custom-script/download/0# javac JDBCSample.java
root@arbitervm:/var/lib/waagent/custom-script/download/0# java -cp .:intersystems-jdbc-3.2.0.jar JDBCSample
Printing out contents of SELECT query:
1, John, Smith
2, Jane, Doe
```
> 内部LBのIPアドレスを引数で指定可能(省略時値は10.0.1.4)。
> ```
> java -cp .:intersystems-jdbc-3.2.0.jar JDBCSample 172.16.0.4
> ```

同じコマンドを2回実行すると、同リクエストが同じサーバ(現プライマリメンバ)に到達するためエラーが発生する。
```
root@arbitervm:/var/lib/waagent/custom-script/download/0# java -cp .:intersystems-jdbc-3.2.0.jar JDBCSample
Connecting to jdbc:IRIS://10.0.1.4:51773/MYAPP
Exception in thread "main" java.sql.SQLException: [SQLCODE: <-201>:<Table or view name not unique>]
[Location: <ServerLoop>]
[%msg: <Table 'SQLUser.People' already exists>]
        at com.intersystems.jdbc.IRISConnection.getServerError(IRISConnection.java:918)
        at com.intersystems.jdbc.IRISConnection.processError(IRISConnection.java:1072)
        at com.intersystems.jdbc.InStream.readMessage(InStream.java:204)
        at com.intersystems.jdbc.InStream.readMessage(InStream.java:171)
        at com.intersystems.jdbc.IRISStatement.sendDirectUpdateRequest(IRISStatement.java:444)
        at com.intersystems.jdbc.IRISStatement.Update(IRISStatement.java:425)
        at com.intersystems.jdbc.IRISStatement.executeUpdate(IRISStatement.java:358)
        at JDBCSample.main(JDBCSample.java:26)
```

現プライマリメンバのIRISを停止する。
```
irismeister@msvm0:~$ sudo -u irisowner iris stop iris quietly
irismeister@msvm0:~$ iris list
Configuration 'IRIS'   (default)
        directory:    /usr/irissys
        versionid:    2021.1.0.215.0
        datadir:      /usr/irissys
        conf file:    iris.cpf  (SuperServer port = 51773, WebServer = 52773)
        status:       down, last used Mon Aug 16 09:33:43 2021
        product:      InterSystems IRISHealth
```

この時点で、同コマンドを再実行すると、同リクエストは新プライマリメンバ(旧バックアップメンバ)に到達するため成功する。
```
root@arbitervm:/var/lib/waagent/custom-script/download/0# java -cp .:intersystems-jdbc-3.2.0.jar JDBCSample
Connecting to jdbc:IRIS://10.0.1.4:51773/MYAPP
Printing out contents of SELECT query:
1, John, Smith
2, Jane, Doe
```

### 可用性ゾーンへの変更
arbiter-resources.json及びdatabase-resources.jsonを修正することで、可用性ゾーンへのデプロイに変更可能。
1. "properties"の"availabilitySet"を削除
2. "zones"を追加

変更後のarbiter-resources.jsonの例
```
"dependsOn": [
  "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]"
],
"zones": [
  "[parameters('machineSettings').zone]"
],
"properties": {
  "hardwareProfile": {
    "vmSize": "[parameters('vmSize')]"
  },
```


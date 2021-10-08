# iris shard
WIP  
## リソースグループ
指定したリソースグループ下に下記が作成される。

## デプロイ後のアクセス
### IRIS管理ポータル  

IRISサーバはプライベートネットワーク上のVMにデプロイされる。正常に動作した場合、15分ほどで完了。  
プライベートネットワーク上のVMアクセス用にJumpBoxがデプロイされるので、SSHポートフォワーディングを使用してIRISにアクセスする。bash端末(Windows上のGit bashなどでも可)を2個開き、下記を実行する。

```bash
端末1
ssh -L 8888:data-mastervm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
[adminUsername]@[domainName].japaneast.cloudapp.azure.com
端末2
ssh -L 8889:datavm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
[adminUsername]@[domainName].japaneast.cloudapp.azure.com
端末3
ssh -L 8890:datavm1:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
[adminUsername]@[domainName].japaneast.cloudapp.azure.com
```

例) 
```bash
ssh -L 8888:data-mastervm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
irismeister@my-irishost-1.japaneast.cloudapp.azure.com
端末2
ssh -L 8889:datavm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
irismeister@my-irishost-1.japaneast.cloudapp.azure.com
端末3
ssh -L 8890:datavm1:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
irismeister@my-irishost-1.japaneast.cloudapp.azure.com
```
データサーバ#1(MASTER)  
http://localhost:8888/csp/sys/UtilHome.csp  
データサーバ#2  
http://localhost:8889/csp/sys/UtilHome.csp
データサーバ#3  
http://localhost:8890/csp/sys/UtilHome.csp

## 補足事項
### データのロード
### SimpleMover
```bash
$ ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-irishost-1.japaneast.cloudapp.azure.com
[password入力]
irismeister@jumpboxvm:~$ ssh clientvm
[password入力]
irismeister@clientvm:~$ ./green.sh
```
#### JDBC
```bash
irismeister@clientvm:~$ javac JDBCSample.java
irismeister@clientvm:~$ java -cp .:intersystems-jdbc-3.2.0.jar JDBCSample
```

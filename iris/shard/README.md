# iris shard
WIP  

# アクセス
```bash
ssh -L 8888:data-mastervm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-iris-123.japaneast.cloudapp.azure.com
ssh -L 8889:datavm0:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-iris-123.japaneast.cloudapp.azure.com
ssh -L 8890:datavm1:52773 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-iris-123.japaneast.cloudapp.azure.com

http://localhost:8888/csp/sys/UtilHome.csp SuperUser/sys
http://localhost:8889/csp/sys/UtilHome.csp SuperUser/sys
http://localhost:8890/csp/sys/UtilHome.csp SuperUser/sys
```
# データのロード
## SimpleMover
動かし方
```bash
$ ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-iris-123.japaneast.cloudapp.azure.com
[password入力]
irismeister@jumpboxvm:~$ ssh clientvm
[password入力]
irismeister@clientvm:~$ ./green.sh
```
## JDBC
```bash
irismeister@clientvm:~$ javac JDBCSample.java
irismeister@clientvm:~$ java -cp .:intersystems-jdbc-3.2.0.jar JDBCSample
```

# iris standalone
IRISサーバ用のVMにパブリックIPがアサインされるため直接接続が可能。  
> ポート22(SSH)及び52773(IRIS管理ポータル用のapache)が公開されるので注意

## リソースグループ
指定したリソースグループ下に下記が作成される。
|NAME|	TYPE|	LOCATION|
|--|--|--|
|myNSG	|Network security group	|Japan East|
|myPublicIP	|Public IP address	|Japan East|
|MyubuntuVM	|Virtual machine	|Japan East|
|MyubuntuVM_OSDisk	|Disk	|Japan East|
|myVMNic	|Network interface	|Japan East|
|MyVNET	|Virtual network	|Japan East|

## デプロイ後のアクセス
### IRIS管理ポータル  
下記のURLでアクセスします。
```
http://[domainName].japaneast.cloudapp.azure.com:52773/csp/sys/UtilHome.csp 
例)
http://my-irishost-1.japaneast.cloudapp.azure.com:52773/csp/sys/UtilHome.csp
```
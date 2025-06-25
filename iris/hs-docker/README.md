# HS

デプロイ完了後。はひとまずsshして動作状況を確認する。

```
ssh-keygen -R my-irishost-1.japaneast.cloudapp.azure.com
ssh -i my-azure-keypair.pem irismeister@my-irishost-1.japaneast.cloudapp.azure.com

irismeister@MyubuntuVM:~$ docker images
REPOSITORY                      TAG       IMAGE ID       CREATED          SIZE
hs                              20251     99ba83f008b7   20 minutes ago   11.2GB
hs-base                         20251     23c8bc29cbda   28 minutes ago   7.47GB
hsviewer                        20251     ea60341c5d2f   29 minutes ago   9.43GB
healthshare-docker-webgateway   latest    8206bfa858ee   36 minutes ago   290MB

起動
irismeister@MyubuntuVM:~$ cd kit/HealthShare-Docker/
irismeister@MyubuntuVM:~/kit/HealthShare-Docker$ ./start.sh

```
この時点では下記のURLでSMPにはアクセスできる。

https://my-irishost-1.japaneast.cloudapp.azure.com/csp/sys/UtilHome.csp  (hayashi/demo)  
https://my-irishost-1.japaneast.cloudapp.azure.com/viewer/csp/sys/UtilHome.csp (hayashi/demo)

> 注意：fedearationを有効化すると、上記URLではログインできなくなる。CLIでfedearationを無効化する方法は不明。

NavAppやCVを使うには、Oauth2認証によるSSOfedearationを有効化する必要がある。

Oauth2各種設定のホスト名がhs.example.orgになっているのでAzureのURLそのままでは動作しない。そこで

- ブラウザを動作させるPCの/etc/hostsに下記のようなエントリを追加する(20.243.xxx.xxxはAzureのVMのpublic IP)
```
#azure
20.243.xxx.xxx webgateway.example.org webgateway
20.243.xxx.xxx hs.example.org hs
20.243.xxx.xxx viewer.example.org viewer
```
- HSREGISTRYで Should Single Sign-On be enabled in the federation? をチェック。保存。「Save was successful.」表示が出れば成功。

- Logoutを実行。

- いったんブラウザ終了。下記にアクセスし、SSOログイン出来ることを確認。
https://hs.example.org/csp/sys/UtilHome.csp  (hayashi/demo)  
https://viewer.example.org/viewer/csp/sys/UtilHome.csp (hayashi/demo)  <= ちゃんとFederationが有効になっていればログイン操作不要になっているはず

- HSVIEWER->Navigationをクリックして患者検索画面が表示されれば成功。

> NavigationのURLは https://viewer.example.org/viewer/csp/healthshare/hssys/hsnavigation/ui/index.html#/navigation となる。  
> 本来は外向きWGWである https://webgateway.example.org:59443/viewer/csp/sys/UtilHome.csp 
> にしたかったが、InstallDemoで(hsのサイドカーである)内部向けWGWを使用しているので、viewer.example.org(実体はhs.example.org)経由でのアクセスになる。
> 起動後のマニュアル操作で、WGWを変更することも可能らしいが不明。  
> https://usjira.iscinternal.com/browse/HSIEO-6457

> クライアント証明書によるアクセス制限は保留。これもコンテナベースでは難しい。理由はHealthShare-Docker「クライアント認証」参照。

# Option

fedearationを有効化する前に、port forwardでHSの管理ポータルに接続する方法

> 有効化後はこの方法ではアクセス拒否される

```
ssh -i my-azure-keypair.pem -L 8443:localhost:443 irismeister@my-irishost-1.japaneast.cloudapp.azure.com
```
https://localhost:8443/csp/sys/UtilHome.csp   (sfarrell/demo)  
https://localhost:8443/viewer/csp/sys/UtilHome.csp  


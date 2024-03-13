# HS
see docs\Azure-deplpy.md

https://my-irishost-1.japaneast.cloudapp.azure.com/csp/sys/UtilHome.csp 
https://my-irishost-1.japaneast.cloudapp.azure.com/viewer/csp/sys/UtilHome.csp 

port forwardで済ませる場合(管理ポータルくらいしか動作しない)
ssh -i xxxx.pem -L 8443:localhost:443 irismeister@my-irishost-1.japaneast.cloudapp.azure.com
https://localhost:8443/csp/sys/UtilHome.csp
https://localhost:8443/viewer/csp/sys/UtilHome.csp

NavAppを使うには、Oauth2認証によるSSOを有効化する必要がある。Oauth2各種設定のホスト名がhs.example.orgになっているのでAzureのURLそのままでは動作しない。

1. /etc/hostsに下記のようなエントリを追加する(20.243.xxx.xxxはAzureのVMのpublic IP)
#azure
20.243.xxx.xxx webgateway.example.org webgateway
20.243.xxx.xxx hs.example.org hs
20.243.xxx.xxx viewer.example.org viewer

2. HSREGISTRYで Should Single Sign-On be enabled in the federation? をチェック。保存。「Save was successful.」表示が出れば成功。
3. 画面の戻る矢印クリックでYour session has ended due to inactivity.表示される。login押下。
4. いったんブラウザ終了。下記にアクセスし、SSOログイン出来ることを確認。
https://hs.example.org/viewer/csp/sys/%25CSP.Portal.Home.zen
1. HSVIEWER->Navigationをクリック

補足) 
URLは
https://hs.example.org/viewer/csp/healthshare/hssys/hsnavigation/ui/index.html#/navigation
となる。本来は外向きWGWである
https://webgateway.example.org/viewer/csp/sys/%25CSP.Portal.Home.zen
にしたかったが、自動セットアップの仕組みで(hsのサイドカーである)内部向けWGWが使用されているので、hs.example.org経由でのアクセスになる。
起動後のマニュアル操作で、WGWを変更することも可能らしいがDocが無い(see stock overflow)。
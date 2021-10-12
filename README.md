# iris arm templates
テスト目的のIRIS環境(スタンドアロン構成、同期ミラーリング構成、シャード構成)をデプロイすることを目的としています。プロダクション用途には使用しないでください。

[こちら](https://github.com/Azure/azure-quickstart-templates)のサイト(特に、[postgre](https://github.com/Azure/azure-quickstart-templates/tree/master/application-workloads/postgre))を参考にさせていただきました。  

# 共通事項

## 事前準備
1. 事前にIRISライセンスキーファイル(iris.key)及びキット(IRIS-2021.1.0.215.0-lnxubuntux64.tar.gzなど)を用意し、**非公開設定**のAzure Blobにアップロードします。

   このURLをパラメータの_secretsLocationで指定します。

2. Generate SASでキー(Signing method:Account key)を作成

   この値をパラメータの_secretsLocationSasTokenで指定します。

  > Azure Blobからのファイル取得は、install_iris.shl内で、下記のようにwgetを実行しています。

```
_secretsLocation => SECRETURL  
_secretsLocationSasToken => SECRETSASTOKEN  
wget "${SECRETURL}/iris.key?${SECRETSASTOKEN}" -O iris.key
```
3. Azure SSH keysで、SSH用のキーペアを作成します。

   公開鍵の値をパラメータのadminPasswordOrKeyで指定します。

4. (オプション)Azure CLIをインストールし、az loginが可能な環境にしておきます。

## デプロイ方法
スタンドアロン構成のデプロイ  
[![Deploy To Azure Standalone](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FIRISMeister%2Fazure-arm%2Fmaster%2Firis%2Fstandalone%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FIRISMeister%2Fazure-arm%2Fmaster%2Firis%2Fstandalone%2Fazuredeploy.json)

ミラーリング構成のデプロイ  
[![Deploy To Azure Mirror](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FIRISMeister%2Fazure-arm%2Fmaster%2Firis%2Fmirror%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FIRISMeister%2Fazure-arm%2Fmaster%2Firis%2Fmirror%2Fazuredeploy.json)


Shard構成のデプロイ  
[![Deploy To Azure Shard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FIRISMeister%2Fazure-arm%2Fmaster%2Firis%2Fshard%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FIRISMeister%2Fazure-arm%2Fmaster%2Firis%2Fshard%2Fazuredeploy.json)

- Azureポータルを使用する場合は、上部のDeploy to Azureリンクを使用してDeploymentを作成します。空白のパラメータに環境に応じた値を設定してください。
- Azure CLIを使用する場合(お勧め)は、同梱のdeploy.shを使用します。
    事前に、以下の要領でパラメータファイル(azuredeploy.parameters.json)を作成し、環境に応じた編集を行います。  

    スタンドアロン構成の場合
    ```bash
    cd standalone
    cp azuredeploy.parameters.template.json azuredeploy.parameters.json
    vi azuredeploy.parameters.json
    ./deploy.sh
    ```
    ミラーリング構成の場合
    ```bash
    cd mirror
    cp azuredeploy.parameters.template.json azuredeploy.parameters.json
    vi azuredeploy.parameters.json
    ./deploy.sh
    ```
    シャード構成の場合
    ```bash
    cd shard
    cp azuredeploy.parameters.template.json azuredeploy.parameters.json
    vi azuredeploy.parameters.json
    ./deploy.sh
    ```
    下記は、ミラー構成用のazuredeploy.parameters.jsonの編集例です。  
```
cat azuredeploy.parameters.json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminUsername": {
      "value": "irismeister" <==任意のLinuxユーザ名を設定
    },
    "adminPasswordOrKey": {
      "value": "ssh-rsa AA ... BX/s= generated-by-azure"  <==公開鍵を設定
    },
    "domainName": {
      "value": "my-irishost-1" <==任意のホスト名を設定
    },
    "_secretsLocation": {
      "value": "https://irismeister.blob.core.windows.net/blob"  <==Azure BlobのURLを設定
    },
    "_secretsLocationSasToken": {
        "value": "sp=r&st=2021..." <==SAS Tokenを設定
    }
  }
}
```
> domainNameに設定するホスト名はユニークである必要があります。
> 以後、上記編集例に習い、adminUsernameには"irismeister", domainNameには"my-irishost-1"を指定した例を使用します。また、デプロイ先のリージョンはjapaneastを指定しています。

## パラメータ一覧

| パラメータ名 | 用途 | 備考 |設定例|
| ------------ | ------ | ---- | --- |
|adminUsername|sudo可能なO/Sユーザ名,全VM共通||irismeister|
|adminPasswordOrKey|SSH public key|ssh接続時に使用|ssh-rsa AAA... generated-by-azure|
|domainName|Public DNS名|StandAloneのIRIS、あるいはMirror/Shard構成のJumpBox用VMのDNSホスト名|my-irishost-1|
|_artifactsLocation|ARMテンプレートのURL|自動設定||
|_artifactsLocationSasToken|同Sas Token|未使用||
|_secretsLocation|プライべートファイルのURL|Azure Blobを想定。Kit,ライセンスキーなど|https://irismeister.blob.core.windows.net/blob|
|_secretsLocationSasToken|同Sas Token||sp=r&st=2021...|
> Public DNS名はユニークである必要があります


## 一括削除方法
```bash
$ rg=IRIS-Group; az group delete --name $rg --yes
```
## デプロイ後のアクセス
### IRIS管理ポータル
IRIS管理ポータルのURLは、デプロイ対象により異なります。  
スタンドアロンの場合は、IRIS稼働VMが持つPublic IPに直接接続します。それ以外の場合は、踏み台ホスト経由で接続します。実際のアクセス方法は、[スタンドアロン](iris\standalone\README.md),[ミラー](iris\mirror\README.md),[シャード](iris\shard\README.md)を参照ください。  

ユーザ名/パスワードはいずれも下記です。
```
SuperUser/sys
```

### SSH
各VMホストへのSSH方法は下記の通りです。ssh秘密鍵ファイルは、[adminPasswordOrKey]で指定したものと対になるものです。
- スタンドアロン  
Public IPが公開されているVM=IRIS稼働VMです。
```bash
$ ssh -i [秘密鍵] [adminUsername]@[domainName].japaneast.cloudapp.azure.com
例)
$ ssh -i my-azure-keypair.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-irishost-1.japaneast.cloudapp.azure.com
```
- それ以外  
Public IPが公開されているVM=踏み台ホストです。各VMには、SSH Agent転送を使用してログインします。
```bash
$ ssh -i [秘密鍵] [adminUsername]@[domainName].japaneast.cloudapp.azure.com -A
$ ssh VM名
例)
$ eval `ssh-agent`
$ ssh-add my-azure-keypair.pem
$ ssh -i my-azure-keypair.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null irismeister@my-irishost-1.japaneast.cloudapp.azure.com -A
irismeister@jumpboxvm:~$ ssh msvm0
irismeister@msvm0:~$ iris list
Configuration 'IRIS'   (default)
        directory:    /usr/irissys
        versionid:    2021.1.0.215.0
        datadir:      /usr/irissys
        conf file:    iris.cpf  (SuperServer port = 1972, WebServer = 52773)
        status:       running, since Wed Aug  4 07:12:45 2021
        mirroring: Member Type = Failover; Status = Primary
        state:        ok
        product:      InterSystems IRISHealth
irismeister@msvm0:~$
```
VM名は以下の通りです。
| デプロイタイプ | VM名 | 用途 |
| ------------ | ------ | ---- |
|mirror|arbitervm|Arbiter|
|mirror|msvm0|ミラープライマリメンバ|
|mirror|slvm0|ミラーバックアップメンバ|
|shard|clientvm|汎用クライアントVM|
|shard|data-mastervm0|データノード #1(マスタ)|
|shard|datavm0|データノード #2|
|shard|datavm1|データノード #3|

### IRISへのログイン
各VMホストへのSSH後の、IRISセッションへのログインはrootユーザであればO/S認証を使用可能です。
```
irismeister@MyubuntuVM:~$ sudo -u irisowner iris session iris
Node: MyubuntuVM, Instance: IRIS
USER>
```


## カスタマイズ
本稿はARMテンプレートやインストーラをGitHubの公開レポジトリに配置することを前提にしています(なので_artifactsLocationSasTokenは未使用)。これらをAzure Blobに配置することも可能ですが、本稿では触れません。  
自前のGitHubの(公開)レポジトリを使用する場合は、deploy.shの下記のuriがそのGitHubレポを差すように修正してください。
```
  --template-uri "https://raw.githubusercontent.com/IRISMeister/azure-arm/$branch/iris/shard/azuredeploy.json" \
```
IRIS自身のインストールは、[install_iris.sh](iris\standalone\install_iris.sh)でサイレントインストールを行っています。その際に、[Silent.Installer.cls](iris\standalone\Installer.cls)が実行されるようになっているので、このクラスに必要な変更を加えてください。タイムゾーン指定(Asia/Tokyo)もinstall_iris.shで行っています。

## デバッグ
### ファイルのデプロイ先
デプロイ時に使用されたファイル群は下記に存在します。stderr,stdout,params.logに実行ログなどが記録されています。
> 実運用上、params.logにあるようなクレデンシャル情報をファイル保存することは好ましくないですが、ここでは利便性を優先しています。  
```bash
irismeister@MyubuntuVM:~$ sudo su -
root@MyubuntuVM:~# cd /var/lib/waagent/custom-script/download/0
root@MyubuntuVM:/var/lib/waagent/custom-script/download/0# ls
IRIS-2021.1.0.215.0-lnxubuntux64.tar.gz  install_iris.sh  iris.service  stderr
Installer.cls                            iris.key         params.log    stdout
root@MyubuntuVM:/var/lib/waagent/custom-script/download/0#
```

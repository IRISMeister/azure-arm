# iris arm templates
WIP
テスト目的のIRIS環境(スタンドアロン構成、同期ミラーリング構成、シャード構成)をデプロイすることを目的としています。プロダクション用途には使用しないでください。

[こちら](https://github.com/Azure/azure-quickstart-templates)のサイト(特に、[postgre](https://github.com/Azure/azure-quickstart-templates/tree/master/application-workloads/postgre))を参考にさせていただきました。  

# 共通事項

## 事前準備
1. 事前にIRISライセンスキーファイル(iris.key)及びキット(IRISHealth-2021.1.0.215.0-lnxubuntux64.tar.gzなど)を用意し、**非公開設定**のAzure Blobにアップロードする(このURLをパラメータの_secretsLocationで指定する)。  
2. Generate SASでキー(Signing method:Account key)を作成(パラメータの_secretsLocationSasTokenで指定する)。  
3. install_iris.shl内から、下記のようにwgetで取得している。ただし  
_secretsLocation => SECRETURL  
_secretsLocationSasToken => SECRETSASTOKEN  
```
wget "${SECRETURL}blob/iris.key?${SECRETSASTOKEN}" -O iris.key
```
4. (オプション)Azure CLIをインストールし、az loginを完了させておく。

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

- Azureポータルを使用する場合は、上部のDeploy to Azureリンクを使用してDeploymentを作成。パラメータに環境に応じた値を設定する。
- Azure CLIを使用する場合(お勧め)は、同梱のdeploy.shを使用。
    事前に、下記の要領でパラメータ用のテンプレート(azuredeploy.parameters.json)を作成し、環境に応じた編集をする。  

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
    以下、ミラー構成用のazuredeploy.parameters.jsonの編集例  
```
cat azuredeploy.parameters.json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminUsername": {
      "value": "irismeister" <==任意のLinuxユーザ名を設定する
    },
    "adminPassword": {
      "value": "abcdEFG123"  <==任意のパスワード用文字列を設定する
    },
    "domainName": {
      "value": "my-iris-123" <==任意のホスト名を設定する
    },
    "_secretsLocation": {
      "value": "https://irismeister.blob.core.windows.net/"  <==Azure BlobのURLを設定する
    },
    "_secretsLocationSasToken": {
        "value": "sp=r&st=2021..." <==正しいSAS Tokenを設定する
    }
  }
}
```
> 以後、上記編集例に習い、adminUsernameには"irismeister", domainNameには"my-iris-123"を指定した例を使用している。

## 一括削除方法
```bash
$ rg=IRIS-Group; az group delete --name $rg --yes
```

## カスタマイズ手順
本稿はARMテンプレートやインストーラをGitHubの公開レポジトリに配置することを前提にしている(それゆえ_artifactsLocationSasTokenは未使用)。Azure Blobに配置することも可能だが、本稿では触れない。

1. 自前のGitHubレポジトリ(公開)を作成する
2. 本レポジトリをcloneしたものをベースに修正を加える
3. deploy.shの下記のuriを自前のGitHubレポを差すように修正する
```
  --template-uri "https://raw.githubusercontent.com/IRISMeister/azure-arm/$branch/iris/shard/azuredeploy.json" \
```
4. 自前のGitHubレポジトリにpush
5. deploy.shを実行

## デバッグ
### ファイルのデプロイ先
デプロイに使用されるファイル群は下記に存在する。stderr,stdout,params.logに実行ログなどが記録されている。
> 実運用上、params.logにあるようなクレデンシャル情報をファイル保存することは好ましくないが、ここでは利便性を優先  
```bash
irismeister@MyubuntuVM:~$ sudo su -
root@MyubuntuVM:~# cd /var/lib/waagent/custom-script/download/0
root@MyubuntuVM:/var/lib/waagent/custom-script/download/0# ls
IRIS-2021.1.0.215.0-lnxubuntux64.tar.gz  install_iris.sh  iris.service  stderr
Installer.cls                            iris.key         params.log    stdout
root@MyubuntuVM:/var/lib/waagent/custom-script/download/0#
```

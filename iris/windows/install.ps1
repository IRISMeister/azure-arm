Param($SASTOKEN,$SECRETSLOCATION,$IRISKITNAME)
# IISインストール
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Chromeインストール
$chromeInstaller = "$env:TEMP\\chrome_installer.exe"
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $chromeInstaller
Start-Process -FilePath $chromeInstaller -Args "/silent /install" -Wait
Remove-Item $chromeInstaller

# IRISキットの取得
# 余計な'が入るので、削除する。
$SASTOKEN=$SASTOKEN.Replace("'","")
$IRISKITNAME=$IRISKITNAME+".exe"

echo "SECRETSLOCATION=${SECRETSLOCATION}" > params.ps1
echo "SASTOKEN=${SASTOKEN}" >> params.ps1
echo "IRISKITNAME=${IRISKITNAME}" >> params.ps1

wget ${SECRETSLOCATION}/${IRISKITNAME}?${SASTOKEN} -O $IRISKITNAME
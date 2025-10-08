Param($SASTOKEN,$SECRETSLOCATION,$KITNAME)
# IISインストール
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Chromeインストール
$chromeInstaller = "$env:TEMP\\chrome_installer.exe"
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $chromeInstaller
Start-Process -FilePath $chromeInstaller -Args "/silent /install" -Wait
Remove-Item $chromeInstaller

# IRISキットの取得
$KITNAME="IRIS-2025.1.1.313.1-win_x64"+".exe"
wget ${SECRETSLOCATION}/${KITNAME}?${SASTOKEN} -O $KITNAME
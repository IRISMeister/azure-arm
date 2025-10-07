# IISインストール
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Chromeインストール
$chromeInstaller = "$env:TEMP\\chrome_installer.exe"
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $chromeInstaller
Start-Process -FilePath $chromeInstaller -Args "/silent /install" -Wait
Remove-Item $chromeInstaller
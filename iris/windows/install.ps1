Param($SASTOKEN,$SECRETSLOCATION,$IRISKITNAME,$IRISUSERPASSWORD)

# set JST TimeZone
tzutil /s "Tokyo Standard Time"
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1

# show fileext and hidden file
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# IISインストール
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Chromeインストール
$chromeInstaller = "$env:TEMP\\chrome_installer.exe"
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $chromeInstaller
Start-Process -FilePath $chromeInstaller -Args "/silent /install" -Wait
Remove-Item $chromeInstaller

# Azure BLOBからIRISキットを取得
# 余計な'が入るので、削除する。
$SASTOKEN=$SASTOKEN.Replace("'","")
$IRISKITNAME=$IRISKITNAME+".exe"

echo "SECRETSLOCATION=${SECRETSLOCATION}" > params.ps1
echo "SASTOKEN=${SASTOKEN}" >> params.ps1
echo "IRISKITNAME=${IRISKITNAME}" >> params.ps1
echo "IRISUSERPASSWORD=${IRISUSERPASSWORD}" >> params.ps1

wget ${SECRETSLOCATION}/${IRISKITNAME}?${SASTOKEN} -O $IRISKITNAME

# IRISインストール

$irisdir="c:\InterSystems\IRIS"
$irissvcname="IRIS_c-_intersystems_iris"
$irisdbdir="c:\InterSystems\db\"
$irisjrndir="c:\iris\jrnl\pri"
$irisjrnaltdir="c:\iris\jrnl\alt"
$iris=$irisdir+"\bin\iris.exe"
$irismgr=$irisdir+"\mgr"
$cur=$PWD.Path

& .\$IRISKITNAME /instance IRIS /qn INSTALLERMANIFESTLOGFILE=C:\temp\silentinstall.log INSTALLDIR=$irisdir INITIALSECURITY=Normal ISCSTARTLAUNCHER=0 IRISUSERPASSWORD=$IRISUSERPASSWORD SUPERSERVERPORT=1972 WEBSERVERPORT=80 INSTALLERMANIFEST=${cur}\MyInstaller.xml

#INSTALLERMANIFEST=c:\temp\irisdistr\MyInstaller.xml INSTALLERMANIFESTPARAMS=ConfigGlobalBuffers=$ConfigGlobalBuffers,DBDir=$irisdbdir,JrnDir=$irisjrndir,JrnAltDir=$irisjrnaltdir

Param($SASTOKEN,$SECRETSLOCATION,$IRISKITNAME,$ADMINUSERNAME,$IRISUSERPASSWORD)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
wget ${SECRETSLOCATION}/iris.key?${SASTOKEN} -O iris.key


# Disk初期化
# 固定値。動的にするならcloudformation参照。
$VolumeName="DISK1"
New-Item -Force -Type File drives.diskpart.txt
echo "select disk 2"  | out-file -append -encoding UTF8 drives.diskpart.txt 
echo "online disk noerr"          | out-file -append -encoding UTF8 drives.diskpart.txt
echo "attributes disk clear readonly"   | out-file -append -encoding UTF8 drives.diskpart.txt
echo "clean"                            | out-file -append -encoding UTF8 drives.diskpart.txt
echo "convert gpt"                      | out-file -append -encoding UTF8 drives.diskpart.txt
echo "create partition primary"         | out-file -append -encoding UTF8 drives.diskpart.txt
echo "format quick fs=ntfs label=${VolumeName}" | out-file -append -encoding UTF8 drives.diskpart.txt
$DriveLetter="H"
echo "assign letter=${DriveLetter}"             | out-file -append -encoding UTF8 drives.diskpart.txt
diskpart /s .\drives.diskpart.txt > .\diskpart.log

# IRISインストール
$irisdir="c:\InterSystems\IRIS"
$irismgr=$irisdir+"\mgr"
$cur=$PWD.Path

mkdir $irismgr
Copy-Item -Path .\iris.key -Destination $irismgr

& .\$IRISKITNAME /instance IRIS /qn INSTALLERMANIFESTLOGFILE=C:\temp\silentinstall.log INSTALLDIR=$irisdir INITIALSECURITY=Normal ISCSTARTLAUNCHER=0 IRISUSERPASSWORD=$IRISUSERPASSWORD SUPERSERVERPORT=1972 WEBSERVERPORT=80 INSTALLERMANIFEST=${cur}\MyInstaller.xml INSTALLERMANIFESTPARAMS=ADMINUSERNAME=$ADMINUSERNAME

# \InterSystems\IRIS\bin\iris.exe merge iris C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.20\Downloads\0\merge.cpf
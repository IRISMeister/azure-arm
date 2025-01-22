#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2015 Microsoft Azure
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

install_wgw_service() {
#!/bin/bash -e

TEMPLATEBASEURI=${TEMPLATEURI%/*}
TEMPLATECMNURI=${TEMPLATEURI%/*/*}
TEMPLATEROOTURI=${TEMPLATEURI%/*/*/*}
ADMINHOME=/home/$ADMINUSER

# setup WGW
# construct WGW kit name from IRISKIT name
ARR=(${IRISKIT//-/ })
wgwversion=${ARR[1]}
platform=${ARR[2]}
#platform=lnxubuntu2204x64
#wgwversion=2024.1.2.398.0
wget "${SECRETURL}/WebGateway-${wgwversion}-${platform}.tar.gz?${SECRETSASTOKEN}" -O WebGateway-${wgwversion}-${platform}.tar.gz
tar -xvf WebGateway-${wgwversion}-${platform}.tar.gz

HTTPD_PREFIX=/etc/apache2
ISC_PACKAGE_INITIAL_SECURITY=Normal
ISC_PACKAGE_CSPSYSTEM_PASSWORD=sys
CSPGATEWAYDIR=/opt/webgateway
pushd WebGateway-${wgwversion}-${platform}/install
./GatewayInstall quiet
cp ../${platform}/bin/shared/cvtcfg /opt/webgateway/bin
popd

wget ${TEMPLATEROOTURI}/wgw/iris-ssl.conf
cp iris-ssl.conf /etc/apache2/sites-available/
wget ${TEMPLATEROOTURI}/wgw/webgateway.conf
cp webgateway.conf /opt/webgateway/apache/

wget ${TEMPLATEROOTURI}/wgw/create-cspini.sh
cp create-cspini.sh /opt/webgateway/bin
chmod +x /opt/webgateway/bin/create-cspini.sh
/opt/webgateway/bin/create-cspini.sh

wget ${TEMPLATEROOTURI}/wgw/create_cert_keys.sh
chmod +x create_cert_keys.sh
mkdir -p webgateway/build/ssl/web/
mkdir -p webgateway/build/ssl/browsers/client01/
git clone https://github.com/IRISMeister/apache-ssl.git
./create_cert_keys.sh
mkdir -p /etc/myssl/certs/
mkdir -p /etc/myssl/private/
mkdir -p /etc/apache2/ssl.crt/
cp webgateway/build/ssl/web/server.crt /etc/myssl/certs/server.crt
cp webgateway/build/ssl/web/server.key /etc/myssl/private/server.key
cp webgateway/build/ssl/web/caint.crt /etc/apache2/ssl.crt/server-ca.crt
cp webgateway/build/ssl/browsers/client01/caint.crt /etc/apache2/ssl.crt/ca-bundle.crt

#echo ServerName iris.example.org >> ${HTTPD_PREFIX}/apache2.conf
echo LoadModule csp_module_sa /opt/webgateway/bin/CSPa24.so >> ${HTTPD_PREFIX}/apache2.conf 
echo CSPFileTypes csp cls zen cxw >> ${HTTPD_PREFIX}/apache2.conf 
echo Include /opt/webgateway/apache/webgateway.conf >> ${HTTPD_PREFIX}/apache2.conf

a2enmod socache_shmcb ssl -q
a2ensite iris-ssl -q
systemctl restart apache2

}

install_iris_service() {
#!/bin/bash -e

TEMPLATEBASEURI=${TEMPLATEURI%/*}
TEMPLATECMNURI=${TEMPLATEURI%/*/*}
TEMPLATEROOTURI=${TEMPLATEURI%/*/*/*}
ADMINHOME=/home/$ADMINUSER

# somehow have to wait until NAT G/W is ready to use.... 
for ((i=0; i < 10; i++)); do
	  echo "${i} th try..."
    DEBIAN_FRONTEND=noninteractive apt -qq update ; apt_status=$?
    echo "ping_status is ${apt_status}"
	if [ ${apt_status} = "0" ]; then
		break
	fi
	sleep 10
done

# apt install時のrestartの抑止
#echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/50local.conf

#sudo systemctl stop apparmor
#DEBIAN_FRONTEND=noninteractive sudo apt remove -y apparmor

if [ "$NODETYPE" == "CLIENT" ];
then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y openjdk-8-jdk-headless

  echo "Initializing as Client"
  
  # iris jdbc driver and others
  wget https://github.com/intersystems-community/iris-driver-distribution/blob/main/JDBC/JDK18/intersystems-jdbc-3.9.0.jar  
  wget ${TEMPLATEBASEURI}/JDBCSample.java
  mv *.jar $ADMINHOME
  mv *.java $ADMINHOME

  chown $ADMINUSER:$ADMINUSER $ADMINHOME/*

  # nothing furthor to do for client
  exit 0
else
  # Need java to use LOAD DATA sql command...
  DEBIAN_FRONTEND=noninteractive sudo apt -y update && sudo apt -y install sudo net-tools iproute2 iputils-ping apache2 curl tcpdump language-pack-ja-base language-pack-ja openjdk-8-jre-headless 
  echo 'export LANG=ja_JP.UTF-8' >> ~/.bashrc && echo 'export LANGUAGE="ja_JP:ja"' >> ~/.bashrc

  wget ${TEMPLATECMNURI}/iris.service
  wget ${TEMPLATEBASEURI}/Installer.cls

fi

wget ${TEMPLATEROOTURI}/readme.txt -O $ADMINHOME/readme.txt
chown $ADMINUSER:$ADMINUSER $ADMINHOME/readme.txt

# The vm name (hence hostname) for this node is data-mastervm0
if [ "$NODETYPE" == "MASTER-DATA" ];
then
  echo "Initializing as the first data node (hence DM)"
  IRIS_COMMAND_INIT="##class(Silent.Installer).InitializeCluster()"
fi

# The vm name (hence hostname) for this/these node is/are datavm0,datavm1...
if [ "$NODETYPE" == "SLAVE-DATA" ];
then
  echo "Initializing as data node"
  IRIS_COMMAND_INIT="##class(Silent.Installer).JoinCluster(\"${MASTERIP}\")"
fi
echo IRIS_COMMAND_INIT=\'$IRIS_COMMAND_INIT\' >> params.log

# ++ edit here for optimal settings ++
kit=$IRISKIT 
#kit=IRIS-2024.1.2.398.0-lnxubuntu2204x64
password=sys
ssport=1972
kittemp=/tmp/iriskit
ISC_PACKAGE_INSTALLDIR=/usr/irissys
ISC_PACKAGE_INSTANCENAME=IRIS
ISC_PACKAGE_MGRUSER=irisowner
ISC_PACKAGE_IRISUSER=irisusr
# -- edit here for optimal settings --
echo kit=$kit >> params.log
echo password=$password >> params.log
echo kittemp=$kittemp >> params.log
echo ISC_PACKAGE_INSTALLDIR=$ISC_PACKAGE_INSTALLDIR >> params.log
echo ISC_PACKAGE_INSTANCENAME=$ISC_PACKAGE_INSTANCENAME >> params.log
echo ISC_PACKAGE_MGRUSER=$ISC_PACKAGE_MGRUSER >> params.log
echo ISC_PACKAGE_IRISUSER=$ISC_PACKAGE_IRISUSER >> params.log

# download iris binary kit
wget "${SECRETURL}/${kit}.tar.gz?${SECRETSASTOKEN}" -O $kit.tar.gz

# add a user and group for iris
useradd -m $ISC_PACKAGE_MGRUSER --uid 51773 | true
useradd -m $ISC_PACKAGE_IRISUSER --uid 52773 | true

# mount user disks and create iris related folders 
wget ${TEMPLATECMNURI}/mount-disks.sh
chmod +x ./mount-disks.sh
./mount-disks.sh
# change owner so that IRIS can create folders and database files
chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISUSER /iris
chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISUSER /iris/db
chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISUSER /iris/wij
chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISUSER /iris/journal1
chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISUSER /iris/journal2

# installer (manifest) requires this.
chmod 775 /iris/db

# cpf merge requires this.
chmod 777 /iris/journal1
chmod 777 /iris/journal2

# install iris
mkdir -p $kittemp
chmod og+rx $kittemp

# requird for non-root install
rm -fR $kittemp/$kit | true
tar -xvf $kit.tar.gz -C $kittemp

cp Installer.cls $kittemp/$kit/Installer.cls
chmod 777 $kittemp/$kit/Installer.cls
pushd $kittemp/$kit
sudo ISC_PACKAGE_INSTANCENAME=$ISC_PACKAGE_INSTANCENAME \
ISC_PACKAGE_IRISGROUP=$ISC_PACKAGE_IRISUSER \
ISC_PACKAGE_IRISUSER=$ISC_PACKAGE_IRISUSER \
ISC_PACKAGE_MGRGROUP=$ISC_PACKAGE_MGRUSER \
ISC_PACKAGE_MGRUSER=$ISC_PACKAGE_MGRUSER \
ISC_PACKAGE_INSTALLDIR=$ISC_PACKAGE_INSTALLDIR \
ISC_PACKAGE_UNICODE=Y \
ISC_PACKAGE_INITIAL_SECURITY=Normal \
ISC_PACKAGE_USER_PASSWORD=$password \
ISC_PACKAGE_CSPSYSTEM_PASSWORD=$password \
ISC_PACKAGE_CLIENT_COMPONENTS= \
ISC_PACKAGE_SUPERSERVER_PORT=$ssport \
ISC_PACKAGE_WEB_CONFIGURE=Y \
ISC_INSTALLER_MANIFEST=$kittemp/$kit/Installer.cls \
ISC_INSTALLER_LOGFILE=/var/tmp/iris_installer_log \
ISC_INSTALLER_LOGLEVEL=3 \
./irisinstall_silent
popd
rm -fR $kittemp

# stop iris to apply config settings and license (if any) 
iris stop $ISC_PACKAGE_INSTANCENAME quietly

# copy iris.key from secure location...
wget "${SECRETURL}/iris.key?${SECRETSASTOKEN}" -O iris.key
if [ -e iris.key ]; then
  cp iris.key $ISC_PACKAGE_INSTALLDIR/mgr/
fi

cp iris.service /etc/systemd/system/iris.service
chmod 644 /etc/systemd/system/iris.service
sudo systemctl daemon-reload
sudo systemctl enable ISCAgent.service
sudo systemctl start ISCAgent.service
sudo systemctl enable iris

USERHOME=/home/$ISC_PACKAGE_MGRUSER
# create cpf merge file
cat << 'EOS' > $USERHOME/merge.cpf
[config]
globals=0,0,2048,0,0,0
gmheap=614400
MaxServerConn=64
MaxServers=64
locksiz=33554432
routines=128
wijdir=/iris/wij/
[Journal]
AlternateDirectory=/iris/journal2/
CurrentDirectory=/iris/journal1/
EOS

# merge cpf
echo "calling systemctl start iris" 
systemctl start iris
echo "merging CPF" 
ISC_PACKAGE_INSTALLDIR=$ISC_PACKAGE_INSTALLDIR iris merge $ISC_PACKAGE_INSTANCENAME $USERHOME/merge.cpf

#echo "calling systemctl restart iris" 
#systemctl restart iris

echo "executing $IRIS_COMMAND_INIT" 
iris session $ISC_PACKAGE_INSTANCENAME -U\%SYS "$IRIS_COMMAND_INIT" 
echo "calling systemctl restart iris" 
systemctl restart iris

# prep to create table(s), if any
if [ "$NODETYPE" == "MASTER-DATA" ];
then
  wget ${TEMPLATEBASEURI}/sql/01.sql
  wget ${TEMPLATEBASEURI}/sql/02.sql
  wget ${TEMPLATEBASEURI}/sql/03.sql
  wget ${TEMPLATEBASEURI}/sql/import.cos

  wget ${TEMPLATEBASEURI}/loader/getfile.sh
  chmod +x ./getfile.sh
  mkdir /var/tmp/data
  wget ${TEMPLATEBASEURI}/loader/conv.py
  ./getfile.sh &

  cp *.sql /home/irisowner/
  chown irisowner:irisowner /home/irisowner/*.sql
  iris session iris -UIRISDM < import.cos

  # do this, later(after all data member has joined).
  #iris session $ISC_PACKAGE_INSTANCENAME -U IRISDM < import.cos
fi

}

# MAIN ROUTINE
if [ ! -f params.log ]; then
# You must be root to run this script
if [ "${UID}" -ne 0 ];
then
    echo "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

# Get today's date into YYYYMMDD format
now=$(date +"%Y%m%d")

# Get passed in parameters $1, $2, $3, $4, and others...
MASTERIP=""
SUBNETADDRESS=""
#CLIENTIP=""
NODETYPE=""
SECRETURL=""
SECRETSASTOKEN=""

#Loop through options passed
while getopts :m:s:a:t:L:T:u:A:I: optname; do
    echo "Option $optname set with value ${OPTARG}"
  case $optname in
    m)
      MASTERIP=${OPTARG}
      ;;
  	s) #Data storage subnet space
      SUBNETADDRESS=${OPTARG}
      ;;
    t) #Type of node (MASTER-DATA/SLAVE-DATA)
      NODETYPE=${OPTARG}
      ;;
    L) #secret url
      SECRETURL=${OPTARG}
      ;;
    T) #secret sas token
      SECRETSASTOKEN=${OPTARG}
      ;;
    u) #template uri
      TEMPLATEURI=${OPTARG}
      ;;
    A) #admin username
      ADMINUSER=${OPTARG}
      ;;
    I) #IRIS kit name
      IRISKIT=${OPTARG}
      ;;
    h)  #show help
      help
      exit 2
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

timedatectl set-timezone Asia/Tokyo
echo "# id=$(id)" >> params.log
echo NOW=$now >> params.log
echo MASTERIP=$MASTERIP >> params.log
echo SUBNETADDRESS=$SUBNETADDRESS >> params.log
echo SECRETURL=$SECRETURL  >> params.log
echo SECRETSASTOKEN=\"$SECRETSASTOKEN\"  >> params.log
echo TEMPLATEURI=$TEMPLATEURI  >> params.log
echo ADMINUSER=$ADMINUSER >> params.log
echo IRISKIT=$IRISKIT >> params.log
#echo CLIENTIP=$CLIENTIP >> params.log
echo NODETYPE=$NODETYPE >> params.log

fi

echo "calling install_iris_service"
install_iris_service
echo "ending install_iris_service"
echo "calling install_wgw_service"
install_wgw_service
echo "ending install_wgw_service"

exit 0

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
ARBITERIP=""
NODETYPE=""
SECRETURL=""
SECRETSASTOKEN=""

#Loop through options passed
while getopts :m:s:a:t:L:T:u:A: optname; do
    echo "Option $optname set with value ${OPTARG}"
  case $optname in
    m)
      MASTERIP=${OPTARG}
      ;;
  	s) #Data storage subnet space
      SUBNETADDRESS=${OPTARG}
      ;;
    a) #arbiter ip address
      ARBITERIP=${OPTARG}
      ;;
    t) #Type of node (MASTER/SLAVE)
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

echo "NOW=$now MASTERIP=$MASTERIP SUBNETADDRESS=$SUBNETADDRESS ARBITERIP=$ARBITERIP NODETYPE=$NODETYPE" >> params.log
echo "SECRETURL=$SECRETURL SECRETSASTOKEN=$SECRETSASTOKEN TEMPLATEURI=$TEMPLATEURI ADMINUSER=$ADMINUSER" >> params.log

install_iris_service() {
#!/bin/bash -e

TEMPLATEBASEURI=${TEMPLATEURI%/*}
TEMPLATECMNURI=${TEMPLATEURI%/*/*}
USERHOME=/home/$ADMINUSER
export MirrorDBName='MYDB'
export MirrorArbiterIP=$ARBITERIP

if [ "$NODETYPE" == "ARBITER" ];
then
  echo "Initializing as Arbiter"
  kit=ISCAgent-2022.1.0.209.0-lnxubuntu2004x64
  mkdir /tmp/irisdistr
  pushd /tmp/irisdistr
  wget "${SECRETURL}/$kit.tar.gz?$SECRETSASTOKEN" -O $kit.tar.gz

  tar -xvf $kit.tar.gz
  cd $kit
  ./agentinstall << END
1
yes
END
  popd
  systemctl daemon-reload
  systemctl enable ISCAgent.service
  systemctl start ISCAgent.service

  # get a jdbc driver for loadbalancer testing purpose
  echo "Installing an ivp java program on Arbiter"

  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y openjdk-8-jdk-headless
  # iris jdbc driver and others
  wget "${SECRETURL}/intersystems-jdbc-3.3.1.jar?${SECRETSASTOKEN}" -O intersystems-jdbc-3.3.1.jar
  mv *.jar $USERHOME
  wget ${TEMPLATEBASEURI}/JDBCSample.java
  mv *.java $USERHOME

  chown irismeister:irismeister $USERHOME/*

  exit 0
else
  wget ${TEMPLATECMNURI}/iris.service
  wget ${TEMPLATEBASEURI}/Installer.cls
fi

if [ "$NODETYPE" == "MASTER" ];
then
  echo "Initializing as PRIMARY mirror member"
  IRIS_COMMAND_INIT="##class(Silent.Installer).CreateMirrorSet(\"${MirrorArbiterIP}\")"
  IRIS_COMMAND_CREATE_DB="##class(Silent.Installer).CreateMirroredDB(\"${MirrorDBName}\")"

fi

if [ "$NODETYPE" == "SLAVE" ];
then
  echo "Initializing as FAILOVER mirror member"
  IRIS_COMMAND_INIT="##class(Silent.Installer).JoinAsFailover(\"${MASTERIP}\")"
  IRIS_COMMAND_CREATE_DB="##class(Silent.Installer).CreateMirroredDB(\"${MirrorDBName}\")"
fi

# ++ edit here for optimal settings ++
kit=IRIS-2022.1.0.209.0-lnxubuntu2004x64 # vanilla IRIS
#kit=IRISHealth-2021.1.0.215.0-lnxubuntux64
password=sys
ssport=1972
webport=52773
kittemp=/tmp/iriskit
ISC_PACKAGE_INSTALLDIR=/usr/irissys
ISC_PACKAGE_INSTANCENAME=iris
ISC_PACKAGE_MGRUSER=irisowner
ISC_PACKAGE_IRISUSER=irisusr
# -- edit here for optimal settings --

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
ISC_PACKAGE_WEBSERVER_PORT=$webport \
ISC_INSTALLER_MANIFEST=$kittemp/$kit/Installer.cls \
ISC_INSTALLER_LOGFILE=installer_log \
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
globals=0,0,128,0,0,0
gmheap=75136
locksiz=33554432
routines=128
wijdir=/iris/wij/
wduseasyncio=1
[Journal]
AlternateDirectory=/iris/journal2/
CurrentDirectory=/iris/journal1/
EOS

# merge cpf
ISC_CPF_MERGE_FILE=$USERHOME/merge.cpf iris start $ISC_PACKAGE_INSTANCENAME quietly
sudo -u irisowner -i iris session $ISC_PACKAGE_INSTANCENAME -U\%SYS "##class(Silent.Installer).EnableMirroringService()"
sleep 2
echo "executing $IRIS_COMMAND_INIT" 
sudo -u irisowner -i iris session $ISC_PACKAGE_INSTANCENAME -U\%SYS "$IRIS_COMMAND_INIT" 

# Without restart, FAILOVER member fails to retrieve (mirror) journal file...and retries forever...
if [ "$NODETYPE" == "SLAVE" ]
then
  sudo iris restart $ISC_PACKAGE_INSTANCENAME quietly
fi

sleep 5
echo "executing $IRIS_COMMAND_CREATE_DB"
sudo -u irisowner -i iris session $ISC_PACKAGE_INSTANCENAME -U\%SYS "$IRIS_COMMAND_CREATE_DB"

}

# MAIN ROUTINE
echo "calling install_iris_service"
install_iris_service
echo "ending install_iris_service"

exit 0

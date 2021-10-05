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

#Format the data disk
bash vm-disk-utils-0.1.sh -s

# Get today's date into YYYYMMDD format
now=$(date +"%Y%m%d")

# Get passed in parameters $1, $2, $3, $4, and others...
MASTERIP=""
SUBNETADDRESS=""
CLIENTIP=""
NODETYPE=""
SECRETURL=""
SECRETSASTOKEN=""

#Loop through options passed
while getopts :m:s:t:L:T:u: optname; do
    echo "Option $optname set with value ${OPTARG}"
  case $optname in
    m)
      MASTERIP=${OPTARG}
      ;;
  	s) #Data storage subnet space
      SUBNETADDRESS=${OPTARG}
      ;;
    t) #Type of node (DATA-0/DATA-1/...)
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

echo "NOW=$now MASTERIP=$MASTERIP SUBNETADDRESS=$SUBNETADDRESS CLIENTIP=$CLIENTIP NODETYPE=$NODETYPE" >> params.log
echo "SECRETURL=$SECRETURL SECRETSASTOKEN=$SECRETSASTOKEN TEMPLATEURI=$TEMPLATEURI" >> params.log

install_iris_service() {

	echo "Start installing IRIS..."
	install_iris_server

}

install_iris_server() {
#!/bin/bash -e

TEMPLATEBASEURI=${TEMPLATEURI%/*}
USERHOME=/home/irismeister

if [ "$NODETYPE" == "CLIENT" ];
then
  echo "Initializing as Client"
  # occasionally apt-get update fails
  # Some packages could not be installed. This may mean that you have
  # requested an impossible situation or if you are using the unstable
  # distribution that some required packages have not yet been created
  # or been moved out of Incoming.
  sleep 10
  
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y openjdk-8-jdk-headless

  # iris jdbc driver
  wget https://github.com/intersystems-community/iris-driver-distribution/raw/main/JDK18/intersystems-jdbc-3.2.0.jar
  wget https://github.com/intersystems-community/iris-driver-distribution/raw/main/JDK18/intersystems-xep-3.2.0.jar
  wget https://github.com/intersystems-community/iris-driver-distribution/raw/main/JDK18/intersystems-utils-3.2.0.jar
  mv *.jar $USERHOME

  # sample open data
  wget https://s3.amazonaws.com/nyc-tlc/trip+data/green_tripdata_2016-01.csv -O - | sed  '/^.$/d' > ./green_tripdata_2016-01.csv
  mv *.csv $USERHOME

  wget ${TEMPLATEBASEURI}/loader/envs.sh
  wget ${TEMPLATEBASEURI}/loader/green.sh
  wget ${TEMPLATEBASEURI}/loader/green.conf
  wget ${TEMPLATEBASEURI}/JDBCSample.java
  chmod +x *.sh
  mv *.sh $USERHOME
  mv *.conf $USERHOME
  mv *.java $USERHOME

  chown irismeister:irismeister $USERHOME/*

  exit 0
else
 wget ${TEMPLATEBASEURI}/iris.service
 wget ${TEMPLATEBASEURI}/Installer.cls
fi

# The vm name (hence hostname) for this node is data-mastervm0
if [ "$NODETYPE" == "DATA-0" ];
then
  echo "Initializing as the first data node (hence DM)"
  IRIS_COMMAND_INIT_SHARD="##class(Silent.Installer).InitializeCluster()"
fi

# The vm name (hence hostname) for this/these node is/are datavm0,datavm1...
if [ "$NODETYPE" == "DATA-1" ];
then
  echo "Initializing as data node"
  IRIS_COMMAND_INIT_SHARD="##class(Silent.Installer).JoinCluster(\"${MASTERIP}\")"
fi

# ++ edit here for optimal settings ++
kit=IRIS-2021.1.0.215.0-lnxubuntux64 # vanilla IRIS
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

wget "${SECRETURL}blob/${kit}.tar.gz?${SECRETSASTOKEN}" -O $kit.tar.gz

# add a user and group for iris
useradd -m $ISC_PACKAGE_MGRUSER --uid 51773 | true
useradd -m $ISC_PACKAGE_IRISUSER --uid 52773 | true

#; change owner so that IRIS can create folders and database files
chown irisowner:irisusr /datadisks/disk1/

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
wget "${SECRETURL}blob/iris.key?${SECRETSASTOKEN}" -O iris.key
if [ -e iris.key ]; then
  cp iris.key $ISC_PACKAGE_INSTALLDIR/mgr/
fi

# create related folders. 
# See https://github.com/IRISMeister/iris-private-cloudformation/blob/master/iris-full.yml for more options
mkdir /iris
mkdir /iris/wij
mkdir /iris/journal1
mkdir /iris/journal2
chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISUSER /iris
chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISUSER /iris/wij
chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISUSER /iris/journal1
chown $ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISUSER /iris/journal2

# any better way?
chmod 777 /iris/journal1
chmod 777 /iris/journal1

cp iris.service /etc/systemd/system/iris.service
chmod 644 /etc/systemd/system/iris.service
sudo systemctl daemon-reload
sudo systemctl enable ISCAgent.service
sudo systemctl start ISCAgent.service
sudo systemctl enable iris

USERHOME=/home/$ISC_PACKAGE_MGRUSER
# additional config if any
cat << 'EOS' > $USERHOME/merge.cpf
[Startup]
EnableSharding=1

[config]
globals=0,0,128,0,0,0
gmheap=75136
MaxServerConn=64
MaxServers=64
locksiz=33554432
routines=128
wijdir=/iris/wij/
wduseasyncio=1
[Journal]
AlternateDirectory=/iris/journal2/
CurrentDirectory=/iris/journal1/
EOS

# merge cpf to enable shard.
ISC_CPF_MERGE_FILE=$USERHOME/merge.cpf iris start $ISC_PACKAGE_INSTANCENAME quietly
sleep 2
echo "executing $IRIS_COMMAND_INIT_SHARD" 
sudo -u irisowner -i iris session $ISC_PACKAGE_INSTANCENAME -U\%SYS "$IRIS_COMMAND_INIT_SHARD" 

# Create table(s), if any
if [ "$NODETYPE" == "DATA-0" ];
then
  wget ${TEMPLATEBASEURI}/sql/01_createtable.sql -O /home/irisowner/01_createtable.sql
  wget ${TEMPLATEBASEURI}/sql/import.cos

  chown irisowner:irisowner /home/irisowner/01_createtable.sql
  export sqls=$(pwd); sudo -u irisowner -i iris session $ISC_PACKAGE_INSTANCENAME -U IRISDM < import.cos
fi

}

# MAIN ROUTINE
echo "calling install_iris_service"
install_iris_service
echo "ending install_iris_service"

exit 0

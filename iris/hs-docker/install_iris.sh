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
NODETYPE=""
SECRETURL=""
SECRETSASTOKEN=""

#Loop through options passed
while getopts :m:s:a:t:L:T:u:A:D:d: optname; do
    echo "Option $optname set with value ${OPTARG}"
  case $optname in
    m)
      MASTERIP=${OPTARG}
      ;;
  	s) #Data storage subnet space
      SUBNETADDRESS=${OPTARG}
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
    D) Docker Username
      DOCKERUSER=${OPTARG}
      ;;
    d) Docker token
      DOCKERTOKEN=${OPTARG}
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

echo NOW=$now >> params.log
echo MASTERIP=$MASTERIP  >> params.log
echo SUBNETADDRESS=$SUBNETADDRESS >> params.log
echo SECRETURL=$SECRETURL  >> params.log
echo SECRETSASTOKEN=$SECRETSASTOKEN  >> params.log
echo TEMPLATEURI=$TEMPLATEURI  >> params.log
echo ADMINUSER=$ADMINUSER >> params.log
echo DOCKERUSER=$DOCKERUSER >> params.log
echo DOCKERTOKEN=$DOCKERTOKEN >> params.log

install_iris_service() {
#!/bin/bash -e

TEMPLATEBASEURI=${TEMPLATEURI%/*}
TEMPLATECMNURI=${TEMPLATEURI%/*/*}
USERHOME=/home/$ADMINUSER

wget ${TEMPLATECMNURI}/iris.service
wget ${TEMPLATEBASEURI}/Installer.cls
# ++ edit here for optimal settings ++
kit=IRIS-2023.1.3.517.0-lnxubuntu2204x64 # vanilla IRIS
#kit=IRISHealth-2023.1.3.517.0-lnxubuntu2204x64
password=sys
ssport=1972
webport=52773
kittemp=/home/${ADMINUSER}/kit
ISC_PACKAGE_INSTALLDIR=/usr/irissys
ISC_PACKAGE_INSTANCENAME=iris
ISC_PACKAGE_MGRUSER=irisowner
ISC_PACKAGE_IRISUSER=irisusr
# -- edit here for optimal settings --

# download iris binary kit
kitcv=HealthShare_ClinicalViewer-2021.2.2CV-1000-0-lnxubuntux64 
wget "${SECRETURL}/${kitcv}.tar.gz?${SECRETSASTOKEN}" -O $kitcv.tar.gz
kiths=HealthShare_UnifiedCareRecord_Insight_PatientIndex-2021.2.1-1000-0-lnxubuntux64 
wget "${SECRETURL}/${kiths}.tar.gz?${SECRETSASTOKEN}" -O $kiths.tar.gz
kitwg=WebGateway-2021.1.2.338.0-lnxubuntux64
wget "${SECRETURL}/${kitwg}.tar.gz?${SECRETSASTOKEN}" -O $kitwg.tar.gz
kitdc=HealthShare-Docker 
wget "${SECRETURL}/${kitdc}.tar.gz?${SECRETSASTOKEN}" -O $kitdc.tar.gz

# mount user disks and create iris related folders 
wget ${TEMPLATECMNURI}/container-mount-disks.sh
chmod +x ./container-mount-disks.sh
./container-mount-disks.sh

# change owner so that IRIS can create folders and database files
chown ${ADMINUSER}:${ADMINUSER} /iris
chown ${ADMINUSER}:${ADMINUSER} /iris/durable

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ${ADMINUSER}

# src, docker-compose etc...
mkdir $kittemp
tar -xvf $kitdc.tar.gz -C $kittemp
cp $kiths.tar.gz $kittemp/HealthShare-Docker/hs/build/
cp $kitwg.tar.gz $kittemp/HealthShare-Docker/hs/build/
cp $kitcv.tar.gz $kittemp/HealthShare-Docker/viewer/build/
cp $kitwg.tar.gz $kittemp/HealthShare-Docker/webgateway/build/
chown -R ${ADMINUSER}:${ADMINUSER} $kittemp

#rm -fR $kittemp

# copy iris.key from secure location...
wget "${SECRETURL}/iris-hs.key?${SECRETSASTOKEN}" -O $kittemp/HealthShare-Docker/hs/build/iris.key
wget "${SECRETURL}/iris-cv.key?${SECRETSASTOKEN}" -O $kittemp/HealthShare-Docker/viewer/build/iris.key

cd $kittemp/HealthShare-Docker

./create_cert_keys.sh
docker login -u="${DOCKERUSER}" -p="${DOCKERTOKEN}"  containers.intersystems.com
docker compose -f docker-compose-base.yml build hs
./build.sh

exit 0
}

install_iris_service
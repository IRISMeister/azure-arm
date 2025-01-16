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
platform=lnxubuntu2204x64
wgwversion=2024.1.2.398.0
wget "${SECRETURL}/WebGateway-${wgwversion}-${platform}.tar.gz?${SECRETSASTOKEN}" -O WebGateway-${wgwversion}-${platform}.tar.gz
tar -xvf WebGateway-${wgwversion}-${platform}.tar.gz

HTTPD_PREFIX=/etc/apache2
ISC_PACKAGE_PLATFORM=lnxubuntu2004x64
ISC_PACKAGE_INITIAL_SECURITY=Normal
ISC_PACKAGE_CSPSYSTEM_PASSWORD=SYS
CSPGATEWAYDIR=/opt/webgateway
pushd WebGateway-${wgwversion}-${platform}/install
./GatewayInstall quiet
cp ../${platform}/bin/shared/cvtcfg /opt/webgateway/bin
popd

wget ${TEMPLATEROOTURI}/wgw/hs-ssl.conf
cp hs-ssl.conf /etc/apache2/sites-available/
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

#echo ServerName hs.example.org >> ${HTTPD_PREFIX}/apache2.conf
echo LoadModule csp_module_sa /opt/webgateway/bin/CSPa24.so >> ${HTTPD_PREFIX}/apache2.conf 
echo CSPFileTypes csp cls zen cxw >> ${HTTPD_PREFIX}/apache2.conf 
echo Include /opt/webgateway/apache/webgateway.conf >> ${HTTPD_PREFIX}/apache2.conf

a2enmod socache_shmcb ssl -q
a2ensite hs-ssl -q
systemctl restart apache2

}

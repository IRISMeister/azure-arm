#!/bin/bash

dir=$(dirname $0)
pushd $dir

touch CSP.ini
touch CSP.log
touch CSPRT.ini

apacheUser=www-data

chmod 600 CSP.ini
chown $apacheUser CSP.ini
chmod 600 CSP.log
chown $apacheUser CSP.log
chmod 600 CSPRT.ini
chown $apacheUser CSPRT.ini

configAuth=hs
configRsc1=viewer
port=${SERVER_PORT-1972}
username=${USERNAME-CSPSystem}
password=${PASSWORD-SYS}

# [SYSTEM]
./cvtcfg setparameter "CSP.ini" "[SYSTEM]" "System_Manager" "*.*.*.*"
# to prevent [Status=Server] connections. WRC #903951
./cvtcfg setparameter "CSP.ini" "[SYSTEM]" "REGISTRY_METHODS" "Disabled"

# [SYSTEM_INDEX]
./cvtcfg setparameter "CSP.ini" "[SYSTEM_INDEX]" "$configAuth" "Enabled"
./cvtcfg setparameter "CSP.ini" "[SYSTEM_INDEX]" "$configRsc1" "Enabled"

# [Auth server]
./cvtcfg setparameter "CSP.ini" "[${configAuth}]" "Ip_Address" "$configAuth"
./cvtcfg setparameter "CSP.ini" "[${configAuth}]" "TCP_Port" "$port"
./cvtcfg setparameter "CSP.ini" "[${configAuth}]" "Username" "$username"
./cvtcfg setparameter "CSP.ini" "[${configAuth}]" "Password" "$password"

# [Resource server #1]
./cvtcfg setparameter "CSP.ini" "[${configRsc1}]" "Ip_Address" "$configRsc1"
./cvtcfg setparameter "CSP.ini" "[${configRsc1}]" "TCP_Port" "$port"
./cvtcfg setparameter "CSP.ini" "[${configRsc1}]" "Username" "$username"
./cvtcfg setparameter "CSP.ini" "[${configRsc1}]" "Password" "$password"

# [APP_PATH_INDEX]
./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/" "Disabled"
./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/csp" "Enabled"
./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/api" "Enabled"

./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/oauth2" "Enabled"
./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/$configAuth" "Enabled"
./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/$configRsc1" "Enabled"

# [APP_PATH:/]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/]" "Default_Server" "LOCAL"

# [APP_PATH:/csp]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/csp]" "Default_Server" "$configAuth"

# [APP_PATH:/api]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/api]" "Default_Server" "$configAuth"

# [APP_PATH:/oauth2]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/oauth2]" "Default_Server" "$configAuth"
# [APP_PATH:/hs]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/$configAuth]" "Default_Server" "$configAuth"
# [APP_PATH:/viewer]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/$configRsc1]" "Default_Server" "$configRsc1"

popd

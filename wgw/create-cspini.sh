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

port=${SERVER_PORT-1972}
username=${USERNAME-CSPSystem}
password=${PASSWORD-sys}

# [SYSTEM]
./cvtcfg setparameter "CSP.ini" "[SYSTEM]" "System_Manager" "*.*.*.*"
# to prevent [Status=Server] connections. WRC #903951
./cvtcfg setparameter "CSP.ini" "[SYSTEM]" "REGISTRY_METHODS" "Disabled"

# [SYSTEM_INDEX]
./cvtcfg setparameter "CSP.ini" "[SYSTEM_INDEX]" "LOCAL" "Enabled"

./cvtcfg setparameter "CSP.ini" "[LOCAL]" "Username" "$username"
./cvtcfg setparameter "CSP.ini" "[LOCAL]" "Password" "$password"


# [APP_PATH_INDEX]
./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/" "Enabled"
./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/csp" "Enabled"
./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/api" "Enabled"
./cvtcfg setparameter "CSP.ini" "[APP_PATH_INDEX]" "/oauth2" "Enabled"

# [APP_PATH:/]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/]" "Default_Server" "LOCAL"

# [APP_PATH:/csp]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/csp]" "Default_Server" "LOCAL"

# [APP_PATH:/api]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/api]" "Default_Server" "LOCAL"

# [APP_PATH:/oauth2]
./cvtcfg setparameter "CSP.ini" "[APP_PATH:/oauth2]" "Default_Server" "LOCAL"

popd

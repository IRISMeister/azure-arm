# HS
see docs\Azure-deplpy.md

https://my-irishost-1.japaneast.cloudapp.azure.com/csp/sys/UtilHome.csp 
https://my-irishost-1.japaneast.cloudapp.azure.com/viewer/csp/sys/UtilHome.csp 

port forwardで済ませる場合(管理ポータルくらいしか動作しない)
ssh -i xxxx.pem -L 8443:localhost:443 irismeister@my-irishost-1.japaneast.cloudapp.azure.com
https://localhost:8443/csp/sys/UtilHome.csp
https://localhost:8443/viewer/csp/sys/UtilHome.csp

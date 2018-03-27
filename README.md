# python-build-k8s-env

INSTALL
=======

Use iPXE to install CoreOS or CentOS
```
git clone https://github.com/sayya9/python-build-k8s-env.git

cd python-build-k8s-env && ./prepare_k8s_env.sh
```
 
Create PXE configs
```
root/bin/inu-build-global-conf.py -k master -H node1.example.org -c
root/bin/inu-build-global-conf.py -k master -H node1.example.org -e
root/bin/inu-build-global-conf.py -k master -H node1.example.org -r
```

Variables
=======

```
K8SVersion=1.5.6
CoreOSChnanel=stable
CentOSInstallationVersion=7
DeployCoreOS=yes
DeployCentOS=yes
IsChina=no
iPXE_Server_IP=192.168.2.110
GatewayIP=192.168.2.1
ethX=br0
```

# shell-build-k8s-env

The purpose of the repository is to deploy k8s env for internal network.(e.g. banks)

prepare_k8s_env.sh download all necessary packages, docker images, and binaries on OS. It chainload into iPXE to obtain the features of iPXE without the hassle of reflashing from PXE.

inu-build-global-conf.py create all iPXE and k8s configs.


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

```
InstallationKind=master, node, or base
InstallationHostname=hostname
CoreOSInstallationVersion=xxxx.x.x or CentOSInstallationVersion=oooo.o.o
ServerIPAddress=Your_IP_Address
MACAddress=Your_MAC_Address
KubernetesToken=XXXX10.dfaereqfdafef
K8SVersion=1.5.6
RemoveDataLVM=no
UseHostnameOverride=yes

If you select node mode
MasterHostname=Your_Kubernetes_master_Hostname
MasterIPAddress=Your_Kubernetes_master_IP
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

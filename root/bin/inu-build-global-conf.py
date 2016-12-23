#!/usr/bin/python

import sys
import os
import re
import subprocess
import shutil
from optparse import OptionParser

def CheckInstallationKind(InstallationKind):
    if InstallationKind in ['master', 'node', 'base']:
        return True
    else:
        print('Please make sure your installed kind is one of the list.[master/node/base]')
        exit(1)

def CreateInstllationConf(InstallationKind):
    ConfDir = '/var/www/html/data'
    if not os.path.exists(ConfDir):
        os.makedirs(ConfDir)

    ConfFile = ConfDir + '/' + InstallationKind
    f = open(ConfFile, 'w')
    f.write('InstallationKind=' + InstallationKind + '\n')
    f.write('HostName=' + InstallationKind + '.example.org' + '\n')
    f.write('CoreOSInstallationVersion=1185.5.0' + '\n')
    f.write('ServerIPAddress=your_' + InstallationKind + '_IP_Address' + '\n')
    f.write('MACAddress=your_' + InstallationKind + '_MAC_Address' + '\n')
    f.write('KubernetesToken=cafe10.6ffc62b53a82753a'+ '\n')
    f.write('K8SVersion=1.5.1'+ '\n')
    f.write('DataPartition=disk1_size_GiB,disk2_size_GiB,disk3_size_GiB' + '\n')
    if InstallationKind == 'node':
        f.write("MasterIPAddress=your_Kubernetes_master_IP\n")
    f.close()

def EditInstallationConf(InstallationKind):
    ConfDir = '/var/www/html/data'
    ConfFile = ConfDir + '/' + InstallationKind
    if not os.path.isfile(ConfFile):
        print('Please create' + ' your ' + InstallationKind + ' template file.')
    else:
        cmd = os.environ.get('EDITOR', 'vim') + ' ' + ConfFile
        subprocess.call(cmd, shell = True)

def GetConfInfo(InstallationKind):
    ConfDir = '/var/www/html/data'
    ConfFile = ConfDir + '/' + InstallationKind
    InstallationInfo = {}
    f = open(ConfFile)
    for line in f:
        m = re.search('(.*)=(.*)', line.replace('\n', ''))
        InstallationInfo[m.group(1)] = m.group(2)
    return InstallationInfo

def CreatePXEConf(MACAddress):
    pxelinux_cfg = '/var/tftpboot/pxelinux.cfg'
    macd = '01-' + MACAddress.lower().replace(':', '-')
    Template = pxelinux_cfg + '/by_mac.tpl'
    dst = pxelinux_cfg + '/' + macd
    cmd = 'cp ' + Template + ' ' + dst
    subprocess.call(cmd, shell = True)

def CreateiPXECloudConf(InstallationKind, InstallationInfo):
    ConfDir = '/var/www/html/cloud-configs/'
    ipxeTemplate = ConfDir + 'template/ipxe-cloud-config.yml'
    dst = ConfDir + 'ipxe-cloud-config.yml'

    f = open(ipxeTemplate, 'r')
    o = open(dst, 'w')

    for line in f:
        for k, v in InstallationInfo.iteritems():
            line = line.replace(k, v)
        o.write(line)
    f.close()
    o.close()

def CreateCoreOSCloudConf(InstallationKind, InstallationInfo):
    ConfDir = '/var/www/html/cloud-configs/'
    coreosTemplate = ConfDir + 'template/' + InstallationKind + '-coreos-cloud-config.yml'
    dst = ConfDir + InstallationKind  + '-coreos-cloud-config.yml'

    f = open(coreosTemplate, 'r')
    o = open(dst, 'w')

    for line in f:
        for k, v in InstallationInfo.iteritems():
            line = line.replace(k, v)
        o.write(line)
    f.close()
    o.close()

def CreateK8SConf(InstallationKind, CreateK8SConf):
    ConfDir = '/var/www/html/k8s/'
    flist = os.listdir(ConfDir + 'template')

    for fname in flist:
        k8sTemplate = ConfDir + 'template/' + fname
        dst = ConfDir + fname
        f = open(k8sTemplate, 'r')
        o = open(dst, 'w')
        for line in f:
            for k, v in InstallationInfo.iteritems():
                line = line.replace(k, v)
            o.write(line)
        f.close()
        o.close()

def CreateDataPartitionScript(HostName, DataPartition):
    ConfDir = '/var/www/html/parted/'
    dst = ConfDir + 'DataDiskParted.sh'
    if not os.path.exists(ConfDir):
        os.makedirs(ConfDir)
    o = open(dst, 'w')
    o.write('set -e\n\n')
    o.write('if [ -e "/.check_DataDiskParted.sh" ]; then\n    exit 0\nfi\n')
    o.write('parted /dev/sdb --script -- mklabel gpt\n')
    o.write('end=0\n')
    o.write('for i in ' + DataPartition.replace(',', ' ') + '; do\n')
    o.write('    start=$end\n')
    o.write('    end=$[ $start + $i ]\n')
    o.write('    if [ "$start" == "0" ]; then\n')
    o.write('        parted /dev/sdb --script mkpart primary xfs ${start}% ${end}GB\n')
    o.write('    else\n')
    o.write('        parted /dev/sdb --script mkpart primary xfs ${start}GB ${end}GB\n')
    o.write('    fi\n\n')
    o.write('    if [ "$?" != "0" ]; then\n')
    o.write('        parted /dev/sdb --script mkpart primary xfs $start -- -1\n')
    o.write('        exit 1\n')
    o.write('    fi\n')
    o.write('done \n\n')
    o.write('for i in `lsblk -nl | grep "sdb[1-9][0-9]*" | cut -d " " -f 1`; do\n')
    o.write('    mkfs -t xfs -f /dev/$i\n')
    o.write('done\n')
    o.write('touch /.check_DataDiskParted.sh\n')
    o.close()

def UpdateDHCPServer():
    cmd = 'systemctl daemon-reload && systemctl restart dhcp'
    subprocess.call(cmd, shell = True)

if __name__ == '__main__':
    usage = "Usage: %prog [-l] [-k kind] [-c create]"
    parser = OptionParser(usage = usage)
    parser.add_option("-l", "--list", action = "store_true",
            default = False,
            help = "show all OS installed version")
    parser.add_option("-c", "--create", action = "store_true",
            default = False,
            help = "create installation configuration")
    parser.add_option("-e", "--edit", action = "store_true",
            default = False,
            help = "edit installation configuration")
    parser.add_option("-r", "--run", action = "store_true",
            default = False,
            help = "create and update all nessenary cloud-configs")
    parser.add_option("-k", "--kind", type = "string",
            help = "specify client's installation kind [master/node/base]",
            metavar = "type")
    (options, args) = parser.parse_args()

    if len(sys.argv) == 1:
        parser.print_help()
        exit(1)

    ImageDir = '/var/www/html/images/coreos/amd64-usr'
    AllVersion = os.listdir(ImageDir)
    if options.list:
        print('Here is available version:')
        for i in AllVersion:
            print(i)
        exit(0)
    elif CheckInstallationKind(options.kind):
        if options.create:
            CreateInstllationConf(options.kind)
        elif options.edit:
            EditInstallationConf(options.kind)
        elif options.run:
            InstallationInfo = GetConfInfo(options.kind)
            CreatePXEConf(InstallationInfo['MACAddress'])
            CreateiPXECloudConf(options.kind, InstallationInfo)
            CreateCoreOSCloudConf(options.kind, InstallationInfo)
            CreateK8SConf(options.kind, InstallationInfo)
            UpdateDHCPServer()
            CreateDataPartitionScript(InstallationInfo['HostName'], InstallationInfo['DataPartition'])

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
    f.write('CoreOSInstallationVersion=1185.3.0' + '\n')
    f.write('ServerIPAddress=your ' + InstallationKind + ' IP Address' + '\n')
    f.write('MACAddress=your ' + InstallationKind + ' MAC Address' + '\n')
    f.write('KubernetesToken=cafe10.6ffc62b53a82753a'+ '\n')
    f.write('K8SVersion=1.5.1'+ '\n')
    if InstallationKind == 'node':
        f.write("MasterIPAddress=your Kubernetes' master IP\n")
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

def CreateiPXECloudConf(InstallationKind):
    ConfDir = '/var/www/html/cloud-configs/'
    ipxeTemplate = ConfDir + 'template/ipxe-cloud-config.yml'
    dst = ConfDir + 'ipxe-cloud-config.yml'
    InstallationInfo = GetConfInfo(InstallationKind)

    f = open(ipxeTemplate, 'r')
    o = open(dst, 'w')

    for line in f:
        for k, v in InstallationInfo.iteritems():
            line = line.replace(k, v)
        o.write(line)
    f.close()
    o.close()

def CreateCoreOSCloudConf(InstallationKind):
    ConfDir = '/var/www/html/cloud-configs/'
    coreosTemplate = ConfDir + 'template/' + InstallationKind + '-coreos-cloud-config.yml'
    dst = ConfDir + InstallationKind  + '-coreos-cloud-config.yml'
    InstallationInfo = GetConfInfo(InstallationKind)

    f = open(coreosTemplate, 'r')
    o = open(dst, 'w')

    for line in f:
        for k, v in InstallationInfo.iteritems():
            line = line.replace(k, v)
        o.write(line)
    f.close()
    o.close()

def CreateK8SConf(InstallationKind):
    ConfDir = '/var/www/html/k8s/'
    flist = os.listdir(ConfDir + 'template')
    InstallationInfo = GetConfInfo(InstallationKind)

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
            CreateiPXECloudConf(options.kind)
            CreateCoreOSCloudConf(options.kind)
            CreateK8SConf(options.kind)
            UpdateDHCPServer()


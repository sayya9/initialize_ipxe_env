#!/usr/bin/python

import sys
import os
import re
import subprocess
import shutil
from optparse import OptionParser

def CheckInstallationArgs(InstallationKind, InstallationHostname):
    if InstallationKind in ['master', 'node', 'base'] and InstallationHostname:
        return True
    else:
        print('Please make sure your installed kind is one of the list[master/node/base] and hostname has been specified.')
        print('For example: inu-build-global-conf.py -k node -H node1.example.org -c')
        print('             inu-build-global-conf.py -k node -H node1.example.org -e')
        print('             inu-build-global-conf.py -k node -H node1.example.org -r')
        exit(1)

def RenderConf(InstallationInfo, src, dst):
    f = open(src, 'r')
    o = open(dst, 'w')

    for line in f:
        for k, v in InstallationInfo.iteritems():
            line = line.replace(k, v)
        o.write(line)
    f.close()
    o.close()

def CreateInstllationConf(InstallationKind, InstallationHostname):
    ConfDir = '/var/www/html/data/'
    if not os.path.exists(ConfDir):
        os.makedirs(ConfDir)

    ConfFile = ConfDir + InstallationHostname
    f = open(ConfFile, 'w')
    f.write('InstallationKind=' + InstallationKind + '\n')
    f.write('InstallationHostname=' + InstallationHostname + '\n')
    f.write('CoreOSInstallationVersion=1235.6.0' + '\n')
    f.write('ServerIPAddress=your_' + InstallationKind + '_IP_Address' + '\n')
    f.write('MACAddress=your_' + InstallationKind + '_MAC_Address' + '\n')
    f.write('KubernetesToken=cafe10.6ffc62b53a82753a'+ '\n')
    f.write('K8SVersion=1.5.2'+ '\n')
    if InstallationKind == 'node':
        f.write("MasterIPAddress=your_Kubernetes_master_IP\n")
    f.close()

def EditInstallationConf(InstallationKind, InstallationHostname):
    ConfDir = '/var/www/html/data/'
    ConfFile = ConfDir + InstallationHostname
    if not os.path.isfile(ConfFile):
        print('Please create' + ' your ' + InstallationKind + '[' + InstallationHostname + ']' + ' template file.')
    else:
        cmd = os.environ.get('EDITOR', 'vim') + ' ' + ConfFile
        subprocess.call(cmd, shell = True)

def GetConfInfo(InstallationHostname):
    ConfDir = '/var/www/html/data'
    ConfFile = ConfDir + '/' + InstallationHostname
    InstallationInfo = {}
    f = open(ConfFile)
    for line in f:
        m = re.search('(.*)=(.*)', line.replace('\n', ''))
        InstallationInfo[m.group(1)] = m.group(2)
    return InstallationInfo

def CreatePXEConf(InstallationMACAddress, InstallationInfo):
    pxelinux_cfg = '/var/tftpboot/pxelinux.cfg/'
    macd = '01-' + InstallationMACAddress.lower().replace(':', '-')
    src = pxelinux_cfg + 'by_mac.tpl'
    dst = pxelinux_cfg + macd
    RenderConf(InstallationInfo, src, dst)

def CreateBootiPXEConf(InstallationHostname, InstallationInfo):
    ConfDir = '/var/www/html/ipxe/'
    src = ConfDir + 'boot.ipxe.tpl'
    dst = ConfDir + InstallationHostname + '.ipxe'
    RenderConf(InstallationInfo, src, dst)

def CreateiPXECloudConf(InstallationInfo):
    ConfDir = '/var/www/html/cloud-configs/'
    src = ConfDir + 'template/ipxe-cloud-config.yml'
    if not os.path.exists(ConfDir + 'ipxe_stage'):
        os.makedirs(ConfDir + 'ipxe_stage')
    dst = ConfDir + 'ipxe_stage/' + InstallationInfo['InstallationHostname'] + '-ipxe-cloud-config.yml'
    RenderConf(InstallationInfo, src, dst)

def CreateCoreOSCloudConf(InstallationInfo):
    ConfDir = '/var/www/html/cloud-configs/'
    src = ConfDir + 'template/' + InstallationInfo['InstallationKind'] + '-coreos-cloud-config.yml'
    if not os.path.exists(ConfDir + 'coreos_stage'):
        os.makedirs(ConfDir + 'coreos_stage')
    dst = ConfDir + 'coreos_stage/' + InstallationInfo['InstallationHostname'] + '-coreos-cloud-config.yml'
    RenderConf(InstallationInfo, src, dst)

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

def UpdateDHCPServer(InstallationInfo):
    ConfDir = '/etc/dhcp/'
    dst = ConfDir + 'dhcpd.conf'
    f = open(dst, 'r')
    for i in f:
        if re.search(InstallationInfo['MACAddress'], i):
            cmd = 'systemctl daemon-reload && systemctl restart dhcp'
            subprocess.call(cmd, shell = True)
            f.close()
            return True

    f.close()
    o = open(dst, 'a')
    o.write('host ' + InstallationInfo['InstallationHostname'] + ' {\n')
    o.write('  hardware ethernet ' + InstallationInfo['MACAddress'] + ';\n')
    o.write('  fixed-address ' + InstallationInfo['ServerIPAddress'] + ';\n')
    o.write('}\n\n')
    o.close()
    cmd = 'systemctl daemon-reload && systemctl restart dhcp'
    subprocess.call(cmd, shell = True)

if __name__ == '__main__':
    usage = "Usage: %prog [-l] [-H hostname] [-k kind] [-c create]"
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
    parser.add_option("-H", "--hostname", type = "string",
            help = "specify client's hostname",
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
    elif CheckInstallationArgs(options.kind, options.hostname):
        if options.create:
            CreateInstllationConf(options.kind, options.hostname)
        elif options.edit:
            EditInstallationConf(options.kind, options.hostname)
        elif options.run:
            InstallationInfo = GetConfInfo(options.hostname)
            CreatePXEConf(InstallationInfo['MACAddress'], InstallationInfo)
            CreateBootiPXEConf(options.hostname, InstallationInfo)
            CreateiPXECloudConf(InstallationInfo)
            CreateCoreOSCloudConf(InstallationInfo)
            UpdateDHCPServer(InstallationInfo)

#!/usr/bin/python3

import sys
import os
import re
import subprocess
import shutil
import yaml
import tarfile
import fileinput
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
        for k, v in InstallationInfo.items():
            line = line.replace(k, v)
        o.write(line)
    f.close()
    o.close()

def CreateInstllationConf(InstallationKind, InstallationHostname, OSPlatform):
    ConfDir = '/var/www/html/data/'
    if not os.path.exists(ConfDir):
        os.makedirs(ConfDir)

    ConfFile = ConfDir + InstallationHostname
    f = open(ConfFile, 'w')
    f.write('InstallationKind=' + InstallationKind + '\n')
    f.write('InstallationHostname=' + InstallationHostname + '\n')
    if OSPlatform == 'coreos':
        f.write('CoreOSInstallationVersion=1395.0.0' + '\n')
    elif OSPlatform == 'centos':
        f.write('CentOSInstallationVersion=7' + '\n')
    f.write('ServerIPAddress=Your_' + InstallationKind + '_IP_Address' + '\n')
    f.write('MACAddress=Your_' + InstallationKind + '_MAC_Address' + '\n')
    f.write('KubernetesToken=cafe10.6ffc62b53a82753a'+ '\n')
    f.write('K8SVersion=1.5.6'+ '\n')
    f.write('RemoveDataLVM=no'+ '\n')
    f.write('UseHostnameOverride=yes'+ '\n')
    if InstallationKind == 'node':
        f.write("MasterHostname=Your_Kubernetes_master_Hostname\n")
        f.write("MasterIPAddress=Your_Kubernetes_master_IP\n")
    f.close()

def EditInstallationConf(InstallationHostname):
    ConfDir = '/var/www/html/data/'
    ConfFile = ConfDir + InstallationHostname
    if not os.path.isfile(ConfFile):
        print('Please create your template file.')
        print('For example: inu-build-global-conf.py -k node -H node1.example.org -c')
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

def CreatePXEConf(InstallationInfo):
    pxelinux_cfg = '/var/tftpboot/pxelinux.cfg/'
    macd = '01-' + InstallationInfo['MACAddress'].lower().replace(':', '-')
    src = pxelinux_cfg + 'by_mac.tpl'
    dst = pxelinux_cfg + macd
    RenderConf(InstallationInfo, src, dst)

def CreateBootiPXEConf(InstallationInfo):
    ConfDir = '/var/www/html/ipxe/'
    if 'CoreOSInstallationVersion' in InstallationInfo:
        src = ConfDir + 'boot.ipxe.tpl.coreos'
    elif 'CentOSInstallationVersion' in InstallationInfo:
        src = ConfDir + 'boot.ipxe.tpl.centos'
    dst = ConfDir + InstallationInfo['InstallationHostname'] + '.ipxe'
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

def CheckRemoveDataLVM(RemoveDataLVM):
    if RemoveDataLVM == 'yes':
        cmd = 'cp -f /var/www/html/special_case/remove_data_lvm.sh /var/www/html/scripts'
    else:
        cmd = 'rm -f /var/www/html/scripts/remove_data_lvm.sh || true'
    subprocess.call(cmd, shell = True)

def TarScripts(InstallationInfo):
    cmd = 'cd /var/www/html && tar zcvf /var/www/html/soft/scripts.' + InstallationInfo['InstallationHostname'] + '.tgz scripts > /dev/null'
    subprocess.call(cmd, shell = True)

def CreateKickstartConf(InstallationInfo):
    ConfDir = '/var/www/html/ks/'
    src = ConfDir + 'ks.cfg.tpl'
    dst = ConfDir + InstallationInfo['InstallationHostname'] + '.cfg'
    RenderConf(InstallationInfo, src, dst)

def CloudConfigToBash(InstallationInfo):
    cloud_config = open('/var/www/html/cloud-configs/coreos_stage/' + InstallationInfo['InstallationHostname'] + '-coreos-cloud-config.yml')
    x = yaml.load(cloud_config)
    srcDir = '/var/www/html/data/cloud-config_to_bash'

    if os.path.exists(srcDir):
        shutil.rmtree(srcDir)

    for i in range(len(x['write_files'])):
        path = x['write_files'][i]['path']
        content = x['write_files'][i]['content']
        permissions = x['write_files'][i]['permissions']

        if not os.path.exists(srcDir + os.path.dirname(path)):
            os.makedirs(srcDir + os.path.dirname(path))
        w = open(srcDir + path, 'w')
        w.write(content)
        w.close()
        n = int(permissions, 8)
        os.chmod(srcDir + path, n)

    IgnorantList = ['systemd-networkd.service', '00-eth0.network', 'down-interfaces.service', 'etcd2.service', 'update-engine.service', 'locksmithd.service']
    if not os.path.exists(srcDir + '/etc/systemd/system'):
        os.makedirs(srcDir + '/etc/systemd/system')

    for i in range(len(x['coreos']['units'])):
        name = x['coreos']['units'][i]['name']
        if name not in IgnorantList:
            content = x['coreos']['units'][i]['content']
            w = open(srcDir + '/etc/systemd/system/' + name, 'w')
            w.write(content)
            w.close()

    if not os.path.exists(srcDir + '/root'):
        os.makedirs(srcDir + '/root')
    w = open(srcDir + '/root/etcd_args.txt', 'w')
    for k, v in x['coreos']['etcd2'].items():
        w.write('--' + k + ' ' + v + ' ')
    w.close()

    dstDir = '/var/www/html/cloud-config_to_bash/'
    if not os.path.exists(dstDir):
        os.makedirs(dstDir)

    tar = tarfile.open(dstDir + InstallationInfo['InstallationHostname'] + '-cloud-config_to_bash.tgz', "w:gz")
    tar.add(srcDir, arcname=os.path.basename(srcDir))
    tar.close()

def UpdateDnsmasq(InstallationInfo):
    dst = '/etc/dnsmasq.conf'
    f = open(dst, 'r')
    for i in f:
        if re.search(InstallationInfo['MACAddress'], i):
            for mLine in fileinput.input(dst, inplace=True):
                if InstallationInfo['MACAddress'] in mLine:
                    continue
                print(mLine, end='')

        if re.search(InstallationInfo['InstallationHostname'], i):
            for iLine in fileinput.input(dst, inplace=True):
                if InstallationInfo['InstallationHostname'] in iLine:
                    continue
                print(iLine, end='')

    f.close()
    o = open(dst, 'a')
    o.write('dhcp-host=' + InstallationInfo['MACAddress'] + ',' + InstallationInfo['InstallationHostname'] + ',' + InstallationInfo['ServerIPAddress'] + ',12h\n')
    o.close()
    cmd = 'systemctl daemon-reload && systemctl restart dnsmasq-docker'
    subprocess.call(cmd, shell = True)

if __name__ == '__main__':
    usage = "Usage: %prog [-l] [-H hostname] [-k kind] [-c create]"
    parser = OptionParser(usage = usage)
    parser.add_option("-l", "--list", action = "store_true",
            default = False,
            help = "show all OS installed version")
    parser.add_option("-c", "--create", action = "store_true",
            default = False,
            help = "create installation configuration template")
    parser.add_option("-e", "--edit", action = "store_true",
            default = False,
            help = "edit installation configuration")
    parser.add_option("-r", "--run", action = "store_true",
            default = False,
            help = "create and update all nessenary cloud-configs")
    parser.add_option("-k", "--kind", type = "string",
            help = "specify installation kind [master/node/base]",
            metavar = "type")
    parser.add_option("-H", "--hostname", type = "string",
            help = "specify installation hostname",
            metavar = "type")
    parser.add_option("-p", "--platform", type = "string",
            default = 'coreos', help = 'specify OS platform, coreos is default')
    (options, args) = parser.parse_args()

    if len(sys.argv) == 1:
        parser.print_help()
        exit(1)

    if options.list:
        ImageDir = '/var/www/html/images/coreos/amd64-usr'
        AllVersion = os.listdir(ImageDir)
        print('Here is available version:')
        for i in AllVersion:
            print(i)
        exit(0)
    else:
        if options.create:
            if options.kind in ['master', 'node', 'base'] and options.hostname:
                CreateInstllationConf(options.kind, options.hostname, options.platform)
            else:
                print('Please make sure your installed kind is one of the list[master/node/base] and hostname has been specified.')
                print('For example: inu-build-global-conf.py -k node -H node1.example.org -c')
                exit(1)
        elif options.edit:
            if options.hostname:
                EditInstallationConf(options.hostname)
            else:
                print('Please make sure your hostname has been specified.')
                print('For example: inu-build-global-conf.py -H node1.example.org -e')
                exit(1)
        elif options.run:
            if options.hostname:
                InstallationInfo = GetConfInfo(options.hostname)
                if InstallationInfo['UseHostnameOverride'] == 'yes':
                    InstallationInfo['HostnameOverride'] = InstallationInfo['ServerIPAddress']
                elif InstallationInfo['UseHostnameOverride'] == 'no':
                    InstallationInfo['HostnameOverride'] = InstallationInfo['InstallationHostname']
                CheckRemoveDataLVM(InstallationInfo['RemoveDataLVM'])
                CreatePXEConf(InstallationInfo)
                CreateBootiPXEConf(InstallationInfo)
                CreateiPXECloudConf(InstallationInfo)
                CreateCoreOSCloudConf(InstallationInfo)
                if 'CentOSInstallationVersion' in InstallationInfo:
                    CreateKickstartConf(InstallationInfo)
                    CloudConfigToBash(InstallationInfo)
                TarScripts(InstallationInfo)
                UpdateDnsmasq(InstallationInfo)
            else:
                print('Please make sure your hostname has been specified.')
                print('For example: inu-build-global-conf.py -H node1.example.org -r')
                exit(1)

#!/usr/bin/python

import sys
import os
import re
import subprocess
import shutil
from optparse import OptionParser

if __name__ == '__main__':
    usage = 'Usage: %prog [-l] [-m MAC_Address] [-t type] [-V version] [-I IP_Address]'
    parser = OptionParser(usage = usage)
    parser.add_option("-V", "--version", type = "string", default = "1122.3.0",
            help = "specify OS installed version, 1122.3.0 is default",
            metavar = "version")
    parser.add_option("-l", "--list", action = "store_true",
            default = False,
            help = "show all OS installed version")
    parser.add_option("-m", "--mac", type = "string",
            help = "specify client's MAC address",
            metavar = "mac")
    parser.add_option("-t", "--type", type = "string",
            help = "specify client's installation type [master/slave]",
            metavar = "type")
    parser.add_option("-I", "--ip", type = "string",
            help = "specify client's IP address",
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

    elif options.version and options.mac and options.ip and options.type in ['master', 'slave']:
        ConfDir = '/var/www/html/cloud-configs/'
        ipxeTemplate = ConfDir + 'template/ipxe-cloud-config.yml'
        dst = ConfDir + 'ipxe-cloud-config.yml'

        if options.version in AllVersion:
            f = open(ipxeTemplate, 'r')
            o = open(dst, 'w')

            for line in f:
                o.write(line.replace('VersionVar', options.version))
            f.close()
            o.close()

        else:
            print(options.version + ' is not corret version.')
            exit(1)

        tftpbootDir = '/var/tftpboot'
        cmd = 'cd ' + tftpbootDir + ' && ' + 'cp coreos.tpl ' + options.mac.lower() + '.ipxe'
        p = subprocess.Popen(cmd, stdout = subprocess.PIPE,
                stderr = subprocess.PIPE, shell = True)

        Template = ConfDir + 'template/' +  options.type + '-coreos-cloud-config.yml'
        dst = ConfDir + 'coreos-cloud-config.yml'
        f = open(Template, 'r')
        o = open(dst, 'w')
        for line in f:
            o.write(line.replace('ClientIPAddr', options.ip))
        f.close()
        o.close()

        ConfDir = '/etc/dhcp/'
        Template = ConfDir + 'dhcpd.conf.tpl'
        dst = ConfDir + 'dhcpd.conf'
        f = open(Template, 'r')
        o = open(dst, 'w')
        for line in f:
            o.write(line.replace('ClientMACAddr', options.mac.lower()).replace('ClientIPAddr', options.ip))
        f.close()
        o.close()

        cmd = 'systemctl restart dhcp'
        p = subprocess.Popen(cmd, stdout = subprocess.PIPE,
                stderr = subprocess.PIPE, shell = True)

    else:
        print("You miss some crucial options.\n\nExample: " + sys.argv[0] + ' -m 00:0C:29:35:5A:85 -t master -V 1185.3.0 -I 192.168.108.25\n')
        exit(1)


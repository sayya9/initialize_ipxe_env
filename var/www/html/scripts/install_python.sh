# Install python
wget -c -P /opt http://iPXE_Server_IP/soft/ActivePython-2.7.13.2713-linux-x86_64-glibc-2.3.6-401785.tar.gz
cd /opt
tar xzvf ActivePython-2.7.13.2713-linux-x86_64-glibc-2.3.6-401785.tar.gz 2> /dev/null
cd ActivePython-2.7.13.2713-linux-x86_64-glibc-2.3.6-401785 && ./install.sh -I /opt/python-2.7.13.2713
ln -sf /opt/python-2.7.13.2713/bin/easy_install /opt/bin/easy_install
ln -sf /opt/python-2.7.13.2713/bin/pip /opt/bin/pip
ln -sf /opt/python-2.7.13.2713/bin/python /opt/bin/python
ln -sf /opt/python-2.7.13.2713/bin/virtualenv /opt/bin/virtualenv
rm -rf /opt/ActivePython-2.7.13.2713-linux-x86_64-glibc-2.3.6-401785.tar.gz /opt/ActivePython-2.7.13.2713-linux-x86_64-glibc-2.3.6-401785

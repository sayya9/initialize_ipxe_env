# Install python 2.7.10.12
cd /opt
wget -q http://iPXE_Server_IP/soft/ActivePython-2.7.10.12-linux-x86_64.tar.gz
tar xzvf ActivePython-2.7.10.12-linux-x86_64.tar.gz > /dev/null
cd ActivePython-2.7.10.12-linux-x86_64 && ./install.sh -I /opt/python-2.7.10.12/
ln -sf /opt/python-2.7.10.12/bin/easy_install /opt/bin/easy_install
ln -sf /opt/python-2.7.10.12/bin/pip /opt/bin/pip
ln -sf /opt/python-2.7.10.12/bin/python /opt/bin/python
ln -sf /opt/python-2.7.10.12/bin/virtualenv /opt/bin/virtualenv
cd /root
rm -rf /opt/ActivePython-2.7.10.12-linux-x86_64.tar.gz /opt/ActivePython-2.7.10.12-linux-x86_64/

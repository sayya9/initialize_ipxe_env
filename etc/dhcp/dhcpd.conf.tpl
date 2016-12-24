ddns-update-style none;
option domain-name "example.org";
option domain-name-servers 8.8.8.8;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;

subnet 192.168.56.0 netmask 255.255.255.0 {
  range 192.168.56.181 192.168.56.190;
  option routers 192.168.56.1;
  option broadcast-address 192.168.56.255;
  next-server 192.168.56.90;
  filename = "pxelinux.0";
}

host station {
      hardware ethernet MACAddress;
      fixed-address ServerIPAddress;
}

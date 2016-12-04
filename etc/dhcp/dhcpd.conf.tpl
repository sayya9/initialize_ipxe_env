ddns-update-style none;
option domain-name "example.org";
option domain-name-servers 8.8.8.8;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;

subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.181 192.168.1.190;
  option routers 192.168.1.1;
  option broadcast-address 192.168.1.255;
  next-server 192.168.1.108;
  if exists user-class and option user-class = "iPXE" {
    filename = "ClientMACAddr.ipxe";
  } else {
    filename = "undionly.kpxe";
  }
}

host station {
      hardware ethernet ClientMACAddr;
      fixed-address ClientIPAddr;
}

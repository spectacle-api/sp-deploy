#!/bin/bash

set -e

HOSTNAME="jump"
VERBOSE_LOG=/dev/null
INSTALL_USER=`logname`
INSTALL_USER_HOME=`eval echo ~$INSTALL_USER`
source config.env

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

function template() {
  eval "cat <<EOF
$(<$1)
EOF
" 2> /dev/null > $2
}

echo "-- Remove snaps because they suck"
if [ -e /usr/bin/snap ] ; then
  snap remove amazon-ssm-agent
  snap remove lxd
  snap remove core18
  snap remove core20
  snap remove snapd
fi

echo "-- apt update"
DEBIAN_FRONTEND=noninteractive apt-get update >$VERBOSE_LOG

echo "-- Remove apt crap"
DEBIAN_FRONTEND=noninteractive apt-get remove -qq apparmor accountsservice multipath-tools udisks2 policykit-1 unattended-upgrades >$VERBOSE_LOG

echo "-- Add openvpn"
DEBIAN_FRONTEND=noninteractive apt-get install -qq openvpn easy-rsa >$VERBOSE_LOG

echo "-- apt Clean"
DEBIAN_FRONTEND=noninteractive apt-get autoremove -qq >$VERBOSE_LOG
DEBIAN_FRONTEND=noninteractive apt-get clean -qq >$VERBOSE_LOG

echo "-- apt upgrade"
DEBIAN_FRONTEND=noninteractive apt-get upgrade -qq >$VERBOSE_LOG

echo "-- Set hostname and persist it"
hostname $HOSTNAME
echo $HOSTNAME > /etc/hostname
cp "$SCRIPT_DIR/80_hostnames.cfg" /etc/cloud/cloud.cfg.d/80_hostnames.cfg
sed -i "/^127.0.0.1 $HOSTNAME/d" /etc/hosts
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

echo "-- Openvpn stuff"
template "$SCRIPT_DIR/udp.conf.env" /etc/openvpn/udp.conf
template "$SCRIPT_DIR/tcp.conf.env" /etc/openvpn/tcp.conf
cp "$SCRIPT_DIR/iptables.conf" /etc/iptables.conf
cp "$SCRIPT_DIR/rc.local" /etc/rc.local
chmod +x "/etc/rc.local"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/98-jump.conf
rm -rf /etc/openvpn/easy-rsa
make-cadir /etc/openvpn/easy-rsa
template "$SCRIPT_DIR/vars.env" /etc/openvpn/easy-rsa/vars
(cd /etc/openvpn/easy-rsa && ./easyrsa init-pki)
(cd /etc/openvpn/easy-rsa && ./easyrsa --batch build-ca nopass -y)
(cd /etc/openvpn/easy-rsa && ./easyrsa gen-dh)
(cd /etc/openvpn/easy-rsa && ./easyrsa --batch gen-req server nopass)
(cd /etc/openvpn/easy-rsa && ./easyrsa --batch sign-req server server -y)

(cd /etc/openvpn/easy-rsa && ./easyrsa --batch gen-req $INSTALL_USER nopass)
(cd /etc/openvpn/easy-rsa && ./easyrsa --batch sign-req client $INSTALL_USER -y)

openvpn --genkey --secret /etc/openvpn/ta.key
cp /etc/openvpn/ta.key $INSTALL_USER_HOME/
chown $INSTALL_USER $INSTALL_USER_HOME/ta.key

cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/ca.crt $INSTALL_USER_HOME
chown $INSTALL_USER $INSTALL_USER_HOME/ca.crt
cp /etc/openvpn/easy-rsa/pki/issued/$INSTALL_USER.crt $INSTALL_USER_HOME
chown $INSTALL_USER $INSTALL_USER_HOME/$INSTALL_USER.crt
cp /etc/openvpn/easy-rsa/pki/private/$INSTALL_USER.key $INSTALL_USER_HOME
chown $INSTALL_USER $INSTALL_USER_HOME/$INSTALL_USER.key

echo "-- Get rid of systemd-resolved"
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved.service
sed -i 's/#script \"\/sbin\/dhclient-script\"/script \"\/sbin\/dhclient-script\"/' /etc/dhcp/dhclient.conf
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "-- done done"

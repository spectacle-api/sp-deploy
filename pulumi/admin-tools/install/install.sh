#!/bin/bash

set -e

HOSTNAME="admin-tools"
DB_SERVER="db-prod.spectacleapp.lol"
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

echo "-- Add apache2"
DEBIAN_FRONTEND=noninteractive apt-get install -qq apache2 libapache2-mod-php mysql-client >$VERBOSE_LOG

echo "-- Add phpmyadmin"
DEBIAN_FRONTEND=noninteractive apt-get install -qq phpmyadmin >$VERBOSE_LOG

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

echo "-- phpmyadmin stuff"
rm -f /etc/apache2/conf-available/phpmyadmin.conf
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
rm -f /etc/apache2/conf-enabled/phpmyadmin.conf
ln -s /etc/apache2/conf-available/phpmyadmin.conf /etc/apache2/conf-enabled/phpmyadmin.conf
cp "$SCRIPT_DIR/21-phpmyadmin.ini" /etc/php/8.1/apache2/conf.d/
cp "$SCRIPT_DIR/login-cookie.php" /etc/phpmyadmin/conf.d/
template "$SCRIPT_DIR/config-db.php.env" /etc/phpmyadmin/config-db.php

echo "-- Get rid of systemd-resolved"
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved.service
sed -i 's/#script \"\/sbin\/dhclient-script\"/script \"\/sbin\/dhclient-script\"/' /etc/dhcp/dhclient.conf
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "-- done done"

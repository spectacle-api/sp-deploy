#!/bin/bash

set -e

APP_NAME="sp-api"
LOAD_HASH=""
CODE_URL="s3://sp-code/sp-api/$LOAD_HASH.tar.gz"
NODE_COMMAND="node src/server.js"
HOSTNAME=$APP_NAME
NODE_PORT=3000
NGINX_PORT=80
NODE_USER=node
NODE_HOME="/var/$NODE_USER"
REPO_DIR="$NODE_HOME/$APP_NAME"
NODE_ENV="PWD=$REPO_DIR,NODE_ENV=production,NODE_CONFIG_SET=prod,PORT=$NODE_PORT"
CODE_HOME_DIR="$NODE_HOME/$LOAD_HASH-install"
VERBOSE_LOG=/dev/null

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

echo "-- Setup node user"
rm -rf $NODE_HOME
if id "$NODE_USER" &>/dev/null; then
  deluser $NODE_USER >$VERBOSE_LOG
fi
adduser $NODE_USER --home $NODE_HOME --disabled-password --gecos '' >$VERBOSE_LOG

echo "-- Add nodesource repo"
curl -s 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key' | gpg --dearmor > /usr/share/keyrings/nodesource.gpg
echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x jammy main" > /etc/apt/sources.list.d/nodesource.list
echo "deb-src [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x jammy main" >> /etc/apt/sources.list.d/nodesource.list

echo "-- apt update"
DEBIAN_FRONTEND=noninteractive apt-get update >$VERBOSE_LOG

echo "-- Remove apt crap"
DEBIAN_FRONTEND=noninteractive apt-get remove -qq apparmor accountsservice multipath-tools udisks2 policykit-1 unattended-upgrades >$VERBOSE_LOG

echo "-- Add good stuff"
DEBIAN_FRONTEND=noninteractive apt-get install -qq build-essential tmpreaper supervisor awscli nginx >$VERBOSE_LOG

echo "-- Add nodejs"
DEBIAN_FRONTEND=noninteractive apt-get install -qq nodejs >$VERBOSE_LOG

echo "-- apt Clean"
DEBIAN_FRONTEND=noninteractive apt-get autoremove -qq >$VERBOSE_LOG
DEBIAN_FRONTEND=noninteractive apt-get clean -qq >$VERBOSE_LOG

echo "-- apt upgrade"
DEBIAN_FRONTEND=noninteractive apt-get upgrade -qq >$VERBOSE_LOG

echo "-- setup tmpreaper"
sed -i 's/^SHOWWARNING=true/# SHOWWARNING=true/' /etc/tmpreaper.conf

echo "-- Set hostname and persist it"
hostname $HOSTNAME
echo $HOSTNAME > /etc/hostname
cp "$SCRIPT_DIR/80_hostnames.cfg" /etc/cloud/cloud.cfg.d/80_hostnames.cfg
sed -i "/^127.0.0.1 $HOSTNAME/d" /etc/hosts
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

echo "-- Setup swap"
swapoff -a
rm -rf /swapfile
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile >$VERBOSE_LOG
swapon /swapfile
echo "vm.swappiness = 10" > /etc/sysctl.d/99-swap.conf
sysctl -q --system
sed -i "/^\/swapfile/d" /etc/fstab
echo '/swapfile none swap sw 0 0' >> /etc/fstab

echo "-- Setup node repo"
rm -rf "$CODE_HOME_DIR"
sudo -u $NODE_USER mkdir "$CODE_HOME_DIR"
if [[ $CODE_URL == http* ]] ; then
  sudo -u $NODE_USER wget "$CODE_URL" -O "$CODE_HOME_DIR/output.tar.gz"
else
  sudo -u $NODE_USER aws s3 cp "$CODE_URL" "$CODE_HOME_DIR/output.tar.gz"
fi
sudo -u $NODE_USER bash -c "cd \"$CODE_HOME_DIR\" && tar xzf output.tar.gz"
rm "$CODE_HOME_DIR/output.tar.gz"
sudo -u $NODE_USER ln -s "$CODE_HOME_DIR" "$REPO_DIR"

echo "-- Run npm ci, this might take a while"
sudo -u $NODE_USER bash -c "cd \"$CODE_HOME_DIR\" && NO_UPDATE_NOTIFIER=1 npm ci --silent --progress false"

echo "-- Setup instance update on first launch"
echo '#!/bin/bash' >/var/lib/cloud/scripts/per-instance/instance_update.sh
echo "" >>/var/lib/cloud/scripts/per-instance/instance_update.sh
echo "\"$REPO_DIR/node_modules/server-control-s3/scripts/instance_update.sh\"" >>/var/lib/cloud/scripts/per-instance/instance_update.sh
echo "" >>/var/lib/cloud/scripts/per-instance/instance_update.sh
chmod +x /var/lib/cloud/scripts/per-instance/instance_update.sh

echo "-- Setup supervisor"
mkdir -p "/etc/systemd/system/supervisor.service.d/"
cp "$SCRIPT_DIR/supervisor_override.conf" /etc/systemd/system/supervisor.service.d/override.conf
template "$SCRIPT_DIR/app_supervise.conf.env" "/etc/supervisor/conf.d/$APP_NAME.conf"

echo "-- Setup nginx"
template "$SCRIPT_DIR/node_nginx.conf.env" "/etc/nginx/sites-available/$APP_NAME.conf"
rm -f /etc/nginx/sites-enabled/default
ln -sf "/etc/nginx/sites-available/$APP_NAME.conf" "/etc/nginx/sites-enabled/$APP_NAME.conf"

echo "-- Get rid of systemd-resolved"
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved.service
sed -i 's/#script \"\/sbin\/dhclient-script\"/script \"\/sbin\/dhclient-script\"/' /etc/dhcp/dhclient.conf
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "-- done done"

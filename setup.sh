#!/usr/bin/env bash

# force sudo
if [[ $EUID -ne 0 ]]; then
  echo "Getting sudo permissions to run this script..."
  exec sudo /usr/bin/env bash "$0" "$@"
fi

function upnew {
  # args source dest [perms]
  if [[ $1 -nt $2 ]]; then
    cp "$1" "$2"
  fi
  if [[ $# -ge 3 ]]; then
    chmod $3 "$2"
  fi
  return 0
}

set -euo pipefail
shopt -s nullglob
srcdir=$(dirname "$(readlink -f "$0")")

# update apt only if not updated in the last 24 hours
if [[ -z "$(find /var/cache/apt -maxdepth 0 -mtime -1)" ]]; then
  apt update
  apt full-upgrade -y
  snap install core
  snap refresh
fi
apt install -y \
  bash-builtins \
  bash-doc \
  trash-cli \
  pwgen \
  sshfs \
  at \
  recode \
  moreutils \
  toilet toilet-fonts \
  age \
  autossh \
  imagemagick \
  fail2ban \
  apache2 \
  apache2-dev \
  libapache2-mod-php \
  libapache2-mod-security2 \
  libapache2-mod-evasive \
  php-cli \
  bat \
  "$srcdir"/fake-ubuntu-advantage-tools.deb
snap install --classic certbot

# get rid of ubuntu spam...
sed -Ezi.orig \
  -e 's/(def _output_esm_service_status.outstream, have_esm_service, service_type.:\n)/\1    return\n/' \
  -e 's/(def _output_esm_package_alert.*?\n.*?\n.:\n)/\1    return\n/' \
  /usr/lib/update-notifier/apt_check.py
/usr/lib/update-notifier/update-motd-updates-available --force
sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
rm -rf /var/lib/ubuntu-advantage/messages/motd-esm-announce

# custom motd
chmod -x /etc/update-motd.d/*
upnew "$srcdir/00-gonavy" /etc/update-motd.d/00-gonavy a+rx

# apache setup
rm -f "/var/www/html/index.html"
pushd "$srcdir/home"
for f in *; do
  upnew "$f" "/var/www/html/$f" a+r
done
popd
a2enmod userdir
a2enmod cgi
csuconf=/etc/apache2/conf-available/csusers.conf
upnew "$srcdir/csusers.conf" "$csuconf"
upnew "$srcdir/navycs.conf" "/etc/apache2/sites-available/navycs.conf"
a2dissite 000-default
a2ensite navycs
a2enconf csusers

# set up SSL (note, requires dns already set up)
domain='navycs.cc'
email='roche@usna.edu'
[[ -e "/etc/letsencrypt/live/$domain" ]] || certbot --agree-tos -m "$email" --apache -d "$domain,www.$domain"

# create scs and caninst groups
getent group scs >/dev/null || addgroup --gid 10120 scs
getent group caninst >/dev/null || addgroup caninst

# set up /etc/skel
rsync -rulpE "$srcdir/skel/" /etc/skel/

# array of usernames for sudo-enabled users (admins)
sudo_users=( roche )

# users setup
exec 4<"$srcdir/users.txt"
while read -u4 u uid; do
  if ! getent passwd "$u" >/dev/null; then
    pw=$(pwgen -Bcn 10)
    adduser --ingroup scs --uid "$uid" --disabled-password --gecos '' "$u"
    echo "$u:$pw" | chpasswd
    passwd -u "$u"
    echo "$u $pw" >>"$srcdir/INITIAL_PASSWORDS"
  fi
  for g in caninst adm; do
    adduser "$u" "$g" >/dev/null
  done
  if ! grep -Eq "^$u$" "/var/www/html/scs.txt"; then
    echo "$u" >>"/var/www/html/scs.txt"
  fi
  if ! grep -Eq "\b$u\b" "$csuconf"; then
    echo "UserDir enabled $u" >>"$csuconf"
  fi
  homedir=$(getent passwd "$u" | cut -d: -f6)
  for f in .ssh bin web; do
    if [[ ! -e "$homedir/$f" ]]; then
      mkdir -p "$homedir/$f"
      chown "$u":scs "$homedir/$f"
    fi
  done
  chmod a+X "$homedir"
  chmod a+rX "$homedir/web"
  if [[ "$srcdir/authkeys/$u.pub" -nt "$homedir/.ssh/authorized_keys" ]]; then
    cp "$srcdir/authkeys/$u.pub" "$homedir/.ssh/authorized_keys"
    chown "$u":scs "$homedir/.ssh/authorized_keys"
  fi
done
exec 4<&-

systemctl restart apache2

# admin users setup
for u in "${sudo_users[@]}"; do
  getent passwd "$u" >/dev/null || continue
  for g in ubuntu adm dialout cdrom floppy sudo audio dip video plugdev netdev lxd; do
    adduser "$u" "$g" >/dev/null
  done
done

# make sure automatic updgrades are enabled
if [[ ! -e '/etc/apt/apt.conf.d/20auto-upgrades' ]] || ! grep -q '^[^#]*1' '/etc/apt/apt.conf.d/20auto-upgrades'; then
  dpkg-reconfigure --priority=low unattended-upgrades
fi

# ssh setup (caution - will make ubuntu user un-sshable! make sure you have an admin user!)
upnew "$srcdir/cs-ssh.conf" "/etc/ssh/sshd_config.d/cs-ssh.conf"
systemctl restart ssh

:

#!/usr/bin/env bash

# force sudo
if [[ $EUID -ne 0 ]]; then
  echo "Getting sudo permissions to run this script..."
  exec sudo /usr/bin/env bash "$0" "$@"
fi

set -euo pipefail
shopt -s nullglob
srcdir=$(dirname "$(readlink -f "$0")")

# update apt only if not updated in the last 24 hours
[[ -z "$(find /var/cache/apt -maxdepth 0 -mtime -1)" ]] && apt update
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
  "$srcdir"/fake-ubuntu-advantage-tools.deb

# get rid of ubuntu spam...
sed -Ezi.orig \
  -e 's/(def _output_esm_service_status.outstream, have_esm_service, service_type.:\n)/\1    return\n/' \
  -e 's/(def _output_esm_package_alert.*?\n.*?\n.:\n)/\1    return\n/' \
  /usr/lib/update-notifier/apt_check.py
/usr/lib/update-notifier/update-motd-updates-available --force
sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
rm -rf /var/lib/ubuntu-advantage/messages/motd-esm-announce

# create scs and caninst groups
getent group scs >/dev/null || addgroup --gid 10120 scs
getent group caninst >/dev/null || addgroup caninst

# associative array from username -> uid for normal scs+caninst users
declare -A scs_users
scs_users['roche']=32893

# array of usernames for sudo-enabled users (admins)
sudo_users=( roche )

# users setup
for u in "${!scs_users[@]}"; do
  if ! getent passwd "$u" >/dev/null; then
    pw=$(pwgen -Bcn 10)
    adduser --ingroup scs --uid "${sudo_users[$u]}" --disabled-password --gecos '' "$u"
    echo "$u:$pw" | chpasswd
    passwd -u "$u"
    echo "$u $pw" >>"$srcdir/INITIAL_PASSWORDS"
  fi
  for g in caninst; do
    adduser "$u" "$g" >/dev/null
  done
  homedir=$(getent passwd "$u" | cut -d: -f6)
  for f in .ssh bin web; do
    if [[ ! -e "$homedir/$f" ]]; then
      mkdir -p "$homedir/$f"
      chown "$u":scs "$homedir/$f"
    fi
  done
  chmod a+rX "$homedir/web"
  if [[ "$srcdir/authkeys/$u.pub" -nt "$homedir/.ssh/authorized_keys" ]]; then
    cp "$srcdir/authkeys/$u.pub" "$homedir/.ssh/authorized_keys"
    chown "$u":scs "$homedir/.ssh/authorized_keys"
  fi
done

# admin users setup
for u in "${sudo_users[@]}"; do
  getent passwd "$u" >/dev/null || continue
  for g in ubuntu adm dialout cdrom floppy sudo audio dip video plugdev netdev lxd; do
    adduser "$u" "$g" >/dev/null
  done
done

:

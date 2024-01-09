#!/usr/bin/env bash

# WSL connectivity fix script
# Dan Roche, 2023
#
# What this script does:
# * Add two lines to bashrc to set DISPLAY and enable certs in Python
# * Set DNS in WLS manually to look at USNA internal DNS as well as Google external
# * Download DoD certs
#
# Deploying to users who don't have DNS is tricky! This command should work:
# curl -s http://faculty.cs.usna.edu/~roche/fix-wsl.sh --resolve 'faculty.cs.usna.edu:80:10.1.83.71' | bash

cat <<EOF
WSL NETWORKING SETUP SCRIPT for USNA

Any issues, feel free to email roche@usna.edu
EOF

# create a temp directory and make sure to delete it when the script exits
tdir=$(mktemp -d)
function cleanup {
  rm -rf "$tdir"
  return 0
}
trap cleanup EXIT

# add 2 lines to bashrc, making sure to first delete anything previously added
echo
echo "Setting up bashrc..."
touch ~/.bashrc
sed -i '/^### BEGIN_USNA/,/^### END_USNA/d' ~/.bashrc
cat >>~/.bashrc <<EOF2
### BEGIN_USNA
export DISPLAY=:0
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
### END_USNA
EOF2

# run remainin script with root privileges
echo
echo 'Enter your **WSL/UBUNTU PASSWORD** when prompted next.'
script="$tdir/wsl-fix.sh"
cat >"$script" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

# make sure running as root
if [[ $(id -u) != 0 ]]; then
  echo "ERROR: Must run as root (sudo). Try again."
  exit 1
fi

# tell WSL *not* to overwrite the resolv.conf file
wslconf='/etc/wsl.conf'
echo "Editing $wslconf..."
touch "$wslconf"
if ! grep -q 'generateResolvConf' "$wslconf"; then
  sudo tee -a "$wslconf" >/dev/null <<EOF2
[network]
generateResolvConf = false
EOF2
fi

# manually set 3 nameservers in resolv.conf.
# 8.8.8.8 is Google's DNS (public, for outside connections)
# 10.1.74.10 is for the USNA mission network
# 172.21.192.11 is for the GNBA-F non-mission wireless network
rconf='/etc/resolv.conf'
echo "Editing $rconf..."
rm -f "$rconf"
touch "$rconf"
sudo tee "$rconf" >/dev/null <<EOF2
nameserver 10.1.74.10
nameserver 172.21.192.11
nameserver 8.8.8.8
EOF2

# run script to download and install DoD certificates,
# if not already present
echo "Downloading certs..."
if [[ ! -d /usr/local/share/ca-certificates/dod ]]; then
  curl http://apt.cs.usna.edu/ssl/install-ssl-system.sh | bash
fi

echo
echo "ALL DONE - SUCCESS!"
exit 0
EOF

chmod +x "$script"
sudo bash "$script"

exit 0

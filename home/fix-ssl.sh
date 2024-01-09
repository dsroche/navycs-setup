# Bash script to allow ITSD man-in-the-middle attack in Python
# Run as source in bash, e.g.:
#   source fix-ssl.sh
# or to download and run at once:
#   curl -sO 'http://faculty.cs.usna.edu/~roche/fix-ssl.sh' && source ./fix-ssl.sh

scname=${BASH_SOURCE[0]}
if [[ $(basename "$scname") = 'fix-ssl.sh' ]]; then
  # delete this script itself unless someone changed the name of it
  rm "$scname"
fi

cat <<EOF
This program will alter your OpenSSL configuration to allow
insecure connections that do not support RFC 5746, namely
the Palo Alto Networks firewall on the USNA network.
EOF

cfile="$HOME/.openssl.cnf"
echo
if [[ -e $cfile ]]; then
  echo "$cfile already exists. This is probably good!"
  echo "To re-create that file, delete it first and then re-run this script."
else
  echo "Creating .openssl.cnf file in your home directory"
  cat >"$cfile" <<EOF
openssl_conf = openssl_init

[openssl_init]
ssl_conf = ssl_sect

[ssl_sect]
system_default = system_default_sect

[system_default_sect]
Options = UnsafeLegacyRenegotiation
EOF
fi

rcfile="$HOME/.bashrc"
echo
if grep -q 'OPENSSL_CONF' "$rcfile"; then
  echo "$rcfile already mentioned OPENSSL_CONF. This is probably good!"
else
  echo "Adding OPENSSL_CONF line to .bashrc"
  echo "export OPENSSL_CONF=\"$$HOME/.openssl.cnf\"" >>"$rcfile"
fi

echo
echo "Setting the environment varialble now..."
export OPENSSL_CONF="$cfile"

echo
echo "Success... I think! If you see Spongebob below, then you're all good."
echo
python3 -c 'import requests; print(requests.get("https://roche.work/spongebob.txt").text)'

:

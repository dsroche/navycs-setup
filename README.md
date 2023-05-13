# navycs-setup

Setup scripts and public keys for navycs web server

The main setup script is [setup.sh](setup.sh).

## To add a new user

1.  Gather your desired uid and create a public/private key pair

    *   For the uid, login to a CS dept linux machine and run

            id -u

    *   To generate the keypair, you can run

            ssh-keygen -t ed25519

        and your public key will be in `$HOME/.ssh/id_ed25519.pub`


2.  Add a line `USERNAME UID` to the [users.txt](users.txt) file, e.g. by running

        echo "$USER $(id -u)" >>users.txt

3.  Add the desired public key(s) to a file called `USERNAME.pub` in
    the [authkeys](authkeys) directory, e.g. by running

        cp ~/.ssh/id_ed25519.pub authkeys/$USER.pub

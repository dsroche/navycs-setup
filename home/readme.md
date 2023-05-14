# User guide for navycs.cc

Welcome! This README is for faculty members who are hosting a web site
on <https://www.navycs.cc>.

## Getting started

[navycs-setup]: https://github.com/dsroche/navycs-setup

First, follow the instructions on the [github setup page][navycs-setup]
to send your numeric uid and a public key file to Dan Roche or another
admin. They will create your initial account and send an email back to
confirm.

## Limitations

This is a dirt-cheap web server paid for out of pocket; please be kind.

We currently have a "step 2" instance on
[AWS LightSail](https://aws.amazon.com/lightsail/pricing/),
which costs $5/month and has 40GB storage, 1GB RAM, and
2TB outbound data per month.

Based on the limitations of this server, you are asked to
**keep your total files below 1GB in size** and to
**avoid running anything CPU or RAM-intensive**.

## SSH

This host runs an OpenSSH server on port 22 which can *only* be accessed
via SSH public/private keys.

Assuming your private key is in the default location, and your username
matches your USNA username, you should be able to just do

    ssh navycs.cc

If you created the private key in a non-standard location, you can
specify the `-i PRIVATE_KEY_PATH` option to ssh, or add an entry like

    host navycs.cc
        identityfile PRIVATE_KEY_PATH

to your `~/.ssh/config` file.

On the remote end, you are now free to add more ssh login keys by
appending the public key contents to `~.ssh/authorized_keys`.

## Rsync

Rsync is installed. If ssh works, rsync should also work seamlessly over
ssh.

## Website

You should see a folder called `web` in your home directory. That is the
root of your navycs web site hosted at
`https://www.navycs.cc/~YOUR_USERNAME/`

The web server is a standard Apache configuration and supports both http
and https. The `AllowOverrides` option is (dangerously) set to `all`, so
you should be able to put your own `.htaccess` file anywhere and change
any settings you want.

The error and access logs should be readable by you and are located in
the usual locations, e.g. `/var/log/apaghe2/errors.log`.

## If you want something else to be installed or enabled...

...just ask!

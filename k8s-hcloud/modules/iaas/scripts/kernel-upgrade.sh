#! /bin/bash

set -e

apt-get -qq -y update
apt-get -qq -y upgrade
apt-get -qq -y install linux-image-amd64

# avoid systemd killing our background script
systemd-run /bin/sh -c 'sleep 2 && reboot'

exit 0

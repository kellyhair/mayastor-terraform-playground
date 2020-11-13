#! /bin/bash

set -eu

# make sure nvme-tcp module is available
apt-get update
apt-get install -qq -y "linux-modules-extra-$(uname -r)"
# and make sure nvme-tcp modules is loaded on boot
echo nvme-tcp >> /etc/modules-load.d/mayadata-nvme-tcp.conf

# inject hugepages and hugepagesz on kernel commandline
# why kernel cmdline? see kernel doc https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt
# shellcheck disable=SC2016
sed -i /etc/default/grub -es'/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 hugepagesz=2M hugepages=${hugepages_2M_amount}"/'
update-grub

# reboot from script "systemd way"
systemd-run /bin/sh -c 'sleep 2 && reboot'

exit 0

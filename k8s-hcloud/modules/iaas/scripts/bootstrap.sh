#!/bin/bash
set -eu
DOCKER_VERSION=${DOCKER_VERSION:-}
KUBERNETES_VERSION=${KUBERNETES_VERSION:-}
SERVER_UPLOAD_DIR=${SERVER_UPLOAD_DIR:-/nonexistent}

export DEBIAN_FRONTEND=noninteractive

waitforapt(){
  while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
     echo "Waiting for other software managers to finish..."
     sleep 1
  done
}

# set timezone to UTC
rm /etc/localtime; ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime
echo 'Etc/UTC' > /etc/timezone
# Is this really needed?
cat << EOF | debconf-set-selections
tzdata  tzdata/Zones/Indian     select
tzdata  tzdata/Zones/Asia       select
tzdata  tzdata/Zones/Australia  select
tzdata  tzdata/Zones/SystemV    select
tzdata  tzdata/Areas            select  Etc
tzdata  tzdata/Zones/Africa     select
tzdata  tzdata/Zones/US         select
tzdata  tzdata/Zones/Pacific    select
tzdata  tzdata/Zones/Etc        select  UTC
tzdata  tzdata/Zones/Europe     select
tzdata  tzdata/Zones/Arctic     select
tzdata  tzdata/Zones/Antarctica select
tzdata  tzdata/Zones/Atlantic   select
tzdata  tzdata/Zones/America    select
EOF
dpkg-reconfigure -f noninteractive tzdata

# set fireall to use iptables-legacy (required for calico/k8s to work)
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

# disable ipv6 altogether for now
echo 'net.ipv6.conf.all.disable_ipv6 = 1' > /etc/sysctl.d/01-disable-ipv6.conf
sysctl 'net.ipv6.conf.all.disable_ipv6=1'

# basic firewall, proper one is set using modules.iaas.null_resource.cluster_firewall
# NOTE: on master.sh firewall is replaced by one with port 6443 open
mkdir /etc/iptables
cat > /etc/iptables/rules.v4 << EOF
*mangle
:PREROUTING ACCEPT
-F PREROUTING
-A PREROUTING -i eth0 -m tcp -p tcp --dport 22 -j ACCEPT
-A PREROUTING -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A PREROUTING -i eth0 -j DROP
COMMIT
EOF

cat > /etc/systemd/system/local-iptables.service << EOF
[Unit]
Description=Local firewall
DefaultDependencies=no
Wants=network-pre.target systemd-modules-load.service local-fs.target
Before=network-pre.target shutdown.target
After=systemd-modules-load.service local-fs.target
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/iptables-restore --noflush --table mangle /etc/iptables/rules.v4
ExecStop=/bin/true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable local-iptables.service
systemctl start local-iptables.service

# install vim, wireguard, current kernel (needs reboot)
# WARNING: as a workaround in current hetzner image there's 4.19.0-8 on which
# wireguard-dkms cannot be built anymore but it works on 4.19.0-9 kernel
# install has been moved to main.tf (search linux-image-amd64)

waitforapt
apt-get -qq update
apt-get -qq install -y linux-headers-amd64 vim wireguard wireguard-tools wireguard-dkms
echo 'set mouse=' > /root/.vimrc
echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
systemctl restart sshd

# install docker
echo "
Package: docker-ce
Pin: version ${DOCKER_VERSION}.*
Pin-Priority: 1000
" > /etc/apt/preferences.d/docker-ce
waitforapt
apt-get -qq update
apt-get -qq install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
apt-get -qq update && apt-get -qq install -y docker-ce

cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver":"overlay2"
}
EOF

systemctl restart docker.service

# install kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo "
Package: kubelet
Pin: version ${KUBERNETES_VERSION}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubelet

echo "
Package: kubeadm
Pin: version ${KUBERNETES_VERSION}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubeadm

waitforapt
apt-get -qq update
apt-get -qq install -y kubelet kubeadm

mv -v "$SERVER_UPLOAD_DIR/10-kubeadm.conf" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload
systemctl restart kubelet

# this is snippet included in ../main.tf via templatefile()
# All dollar-sign+curly braces are interpolated by terraform; escape by doubling dollar sign.
# Without curly braces dollar signs are safe.

# script runs as user ubuntu with password-less sudo allowed

sudo hostnamectl set-hostname "${hostname}"

# set up multiple ssh public keys for both ${user} and root - allowing ssh to root account which is disabled in authorized_keys by AWS by default
mkdir -p "/home/${user}/.ssh" /root/.ssh/
sudo rm "/home/${user}/.ssh/authorized_keys" /root/.ssh/authorized_keys || true

%{for ssh_public_key in ssh_public_keys~}
echo '${lookup(ssh_public_key, "key_file", "__missing__") == "__missing__" ? trimspace(lookup(ssh_public_key, "key_data")) : trimspace(file(lookup(ssh_public_key, "key_file")))}' >> /home/ubuntu/.ssh/authorized_keys
echo '${lookup(ssh_public_key, "key_file", "__missing__") == "__missing__" ? trimspace(lookup(ssh_public_key, "key_data")) : trimspace(file(lookup(ssh_public_key, "key_file")))}' | sudo tee -a /root/.ssh/authorized_keys
%{endfor~}

# Install kubeadm and Docker
echo "
Package: docker-ce
Pin: version ${docker_version}.*
Pin-Priority: 1000
" > /etc/apt/preferences.d/docker-ce
echo "
Package: kubelet
Pin: version ${kubernetes_version}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubelet

echo "
Package: kubeadm
Pin: version ${kubernetes_version}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubeadm
apt-get update
apt-get install -y apt-transport-https curl
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >/etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y docker.io kubeadm

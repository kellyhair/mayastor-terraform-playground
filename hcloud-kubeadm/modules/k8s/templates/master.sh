#!/bin/bash
set -eu

# Open port 6443 - the rest is the same as in bootstrap.sh
cat > /etc/iptables/rules.v4 << EOF
*mangle
:PREROUTING ACCEPT
-F PREROUTING
-A PREROUTING -i eth0 -m tcp -p tcp --dport 22 -j ACCEPT
-A PREROUTING -i eth0 -m tcp -p tcp --dport 6443 -j ACCEPT
-A PREROUTING -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A PREROUTING -i eth0 -j DROP
COMMIT
EOF
systemctl restart local-iptables.service

# Initialize Cluster
if [ -n "${feature_gates}" ]; then
	kubeadm init --pod-network-cidr="${pod_network_cidr}" --feature-gates "${feature_gates}"
else
	kubeadm init --pod-network-cidr="${pod_network_cidr}"
fi

systemctl enable docker kubelet

mkdir -p "$HOME/.kube"
cp /etc/kubernetes/admin.conf "$HOME/.kube/config"

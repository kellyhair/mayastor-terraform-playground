#! /bin/bash

set -eu

mkdir -p "$(dirname "${KUBEADM_JOIN}")"

# get join command
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	"root@${SSH_HOST}" kubeadm token create --print-join-command > "${KUBEADM_JOIN}"

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	"root@${SSH_HOST}" cat /etc/kubernetes/admin.conf > "${K8S_CONFIG}"


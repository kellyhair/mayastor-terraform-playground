#! /bin/sh
# shellcheck disable=SC2154,SC2039
set -eu

RULES_F=/etc/iptables/rules.v4
tmpf=$(mktemp)
# shellcheck disable=SC2064
trap "rm '$tmpf'" HUP INT QUIT TERM EXIT

cat > "$tmpf" << EOF
# Managed by terraform - do not edit!
*mangle
:PREROUTING ACCEPT [0:0]
-F PREROUTING
-A PREROUTING -i eth0 -m tcp -p tcp --dport 22 -j ACCEPT
-A PREROUTING -s ${k8s_master_ipv4}/32 -i eth0 -m comment --comment k8s_master -j ACCEPT
EOF
if [ "$MASTER" = "true" ]; then
	echo '-A PREROUTING -i eth0 -m tcp -p tcp --dport 6443 -m comment --comment k8s_apiserver -j ACCEPT' >> "$tmpf"
fi

for node_ipv4 in ${k8s_nodes_ipv4}; do
	echo "-A PREROUTING -s ${node_ipv4}/32 -i eth0 -m comment --comment k8s_node -j ACCEPT" >> "$tmpf"
done
cat >> "$tmpf" << EOF
-A PREROUTING -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A PREROUTING -i eth0 -j DROP
COMMIT
EOF

mv "$tmpf" "$RULES_F"
trap - HUP INT QUIT TERM EXIT

systemctl restart local-iptables.service

#! /bin/sh
# shellcheck disable=SC2154
set -eu

# make it persistent
cat > /etc/network/interfaces.d/eth0-fip.cfg << EOF
EOF

# but apply it right away
# removing FIP done by restarting node
# as networking config is fully rewritten above and there is a firewall that is updated when removing FIPs
# if ! ip addr list dev eth0 | grep -qF "{erp_ingress_ip}"; then ip addr add "{erp_ingress_ip}/32" dev eth0; fi


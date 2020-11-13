# TODO

[ ] mayastor pool - creating pool often doesn't work and only one pool is created on one of the nodes, terraform succeeds, but pool isn't created... Race?
[ ] enable metrics/handle(?) for moac
    - `csi-attacher W1109 13:25:33.325934       1 metrics.go:142] metrics endpoint will not be started because `metrics-address` was not specified.`
[ ] remove kernel_upgrade.sh because of ubuntu, just install modules in bootstrap.sh or node.sh
[ ] github actions for terraform validate & fmt, shellcheck and yamllint
[ ] fix auth to kubelet and don't use --deprecated-kubelet-completely-insecure in `module/k8s/install-metrics-server.tf`
[ ] for the love of God handle machines' ssh keys properly instead of ignoring them
    - pass pre-generated keys using `user_data` (`cloud-init`) to `hcloud_server` resource?

# Wishlist

[ ] make modules separable - usable by themselves - probably won't happen
    - document variables and have defaults in modules' `variables.tf`
    - figure out how to get required variable values without top-level module
    - ...?
[ ] somehow partition existing nvme disk to use as a device for mayastor - faster, local, non ceph-based
    - on Debian passing `user_data=resize_rootfs: false`; manually removing sda1 with parted, creating two partitions instead, resizing rootfs and rebooting worked, however on ubuntu with same version of parted I wasn't able to force answers Yes, Ignore to parted for working with used partition. Rescue system might help.

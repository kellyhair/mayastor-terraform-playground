[x] somehow partition existing nvme disk to use for that (or use hcloud iscsi volumes if enough)
    - passing cloud-config with `resize_rootfs: false` we don't resize root fs
    - `modules/iaas/scripts/node-rootfs.sh` we recreate ~10G root partition & create second - free + resize rootfs ourselves
    - can that be done solely using `cloud-init`? it seems it doesn't forced re-creation of partitions over existing ones (which albeit a bit dangerous works without problem)
    - [this](https://gist.github.com/exocode/a7e12b063f23a1ef899b23bcbfc7d123) hasn't worked
    - maybe `run-cmd` cloud-init stanza, but again, how is that better?
[ ] fix `modules/iaas/scripts/node-rootfs.sh` size calculation to be safe
    - hetzner creates 2 partitions (sda14, sda15) bios-boot & EFI-system
        - take them into account
[ ] allow specification of root partition size as variable instead of hardcoded 10G

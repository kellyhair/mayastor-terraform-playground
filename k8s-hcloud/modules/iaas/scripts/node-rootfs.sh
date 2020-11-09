#! /bin/bash

set -xve

# delete /dev/sda1, make it ~4G and create new partition to be used for mayastor
apt-get update && apt-get install -qy parted
parted /dev/sda rm 1 y i
parted -s /dev/sda u s mkpart 1 253952s 21225472s
parted --align optimal -s /dev/sda u s mkpart 2 21225473s 100%
partprobe
resize2fs /dev/sda1


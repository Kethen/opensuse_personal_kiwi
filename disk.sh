#!/bin/bash

set -xe

/usr/libexec/setup-etc-subvol
#/usr/sbin/setup-fstab-for-overlayfs

sed -i 's#/root/.root.keyfile#/root/.root.keyfile x-initrd.attach#' /etc/crypttab

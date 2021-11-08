#!/usr/bin/env bash
set -euxo pipefail

ln -s /dev/disk/by-id/google-registry-data /dev/sdh

REALPATH="$(realpath /dev/sdh)"
# Ensure /dev/sdh has a file system.
if [ "$(file -s "$REALPATH")" == "$REALPATH: data" ]; then
  mkfs.ext4 /dev/sdh
fi

# Mount /dev/sdh to /mnt/registry.
mkdir -p /mnt/registry
echo "/dev/sdh /mnt/registry ext4 defaults 0 2" >>/etc/fstab
mount -a
chown ubuntu:ubuntu /mnt/registry

# Enable and start the registry service.
systemctl enable docker_registry
systemctl start docker_registry

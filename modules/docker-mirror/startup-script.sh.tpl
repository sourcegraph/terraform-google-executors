#!/usr/bin/env bash
set -euxo pipefail

## Pull terraform variables into the environment.
%{ for key, value in environment_variables }
${key}="${replace(value, "\"", "\\\\\\\"")}"
%{ endfor ~}

if [ "$${USE_LOCAL_SSD}" = "true" ]; then
    ln -s /dev/disk/by-id/google-local-nvme-ssd-0 /dev/sdh
else
    ln -s /dev/disk/by-id/google-registry-data /dev/sdh
fi

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

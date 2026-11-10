#!/usr/bin/env bash
set -euxo pipefail

## Pull terraform variables into the environment.
%{ for key, value in environment_variables }
${key}="${replace(value, "\"", "\\\\\\\"")}"
%{ endfor ~}

# Hardware GRO packets can fail software segmentation inside Firecracker guests.
# systemd 250 introduced GenericReceiveOffloadHardware in .link files.
systemd_version=$(systemctl --version | awk 'NR == 1 {print $2}')
if [ "$systemd_version" -lt 250 ]; then
  echo "Executor hosts require systemd 250 or later to disable hardware GRO." >&2
  exit 1
fi

for interface in /sys/class/net/*; do
  [ -L "$interface/device/driver" ] || continue
  driver=$(basename "$(readlink "$interface/device/driver")")
  [ "$driver" = "gve" ] || continue

  # Preserve naming rules, including netplan files used only after a reboot.
  for link_file in /usr/lib/systemd/network/*.link /run/systemd/network/*.link /etc/systemd/network/*.link; do
    [ -f "$link_file" ] || continue
    link_drop_in="/etc/systemd/network/$(basename "$link_file").d"
    mkdir -p "$link_drop_in"
    cat >"$link_drop_in/90-executor-offloads.conf" <<'EOF'
[Link]
GenericReceiveOffloadHardware=no
EOF
  done

  # Startup runs after NIC initialization. Apply the setting on first boot too.
  features=$(ethtool -k "$(basename "$interface")")
  if grep -q '^rx-gro-hw: on' <<<"$features"; then
    ethtool -K "$(basename "$interface")" rx-gro-hw off
  fi
done
udevadm control --reload

# Conditionally set below
DOCKER_REGISTRY_NODE_EXPORTER_URL_LINE=''

export EXECUTOR_DOCKER_REGISTRY_MIRROR_URL="https://mirror.gcr.io"

# If a docker registry mirror is configured, create a startup script
# that will configure docker to use the mirror. This requires writing
# a docker configuration file and restarting the service.
if [ "$${EXECUTOR_DOCKER_REGISTRY_MIRROR}" != '' ]; then
  EXECUTOR_DOCKER_REGISTRY_MIRROR_URL="https://mirror.gcr.io,$${EXECUTOR_DOCKER_REGISTRY_MIRROR}"
  # Allow access to the docker registry from the VM.
  IP=$(echo $${EXECUTOR_DOCKER_REGISTRY_MIRROR} | grep -oE '//(.*?):' | sed 's/[\/:]//g')
  PORT=$(echo $${EXECUTOR_DOCKER_REGISTRY_MIRROR} | grep -oE "(:[0-9]{1,6})" | sed 's/://g')

  iptables -I CNI-ADMIN -p tcp -d $${IP} --dport $${PORT} -j ACCEPT

  # Store the iptables config.
  iptables-save >/etc/iptables/rules.v4

  if [ "$${DOCKER_REGISTRY_NODE_EXPORTER_URL}" != '' ]; then
    DOCKER_REGISTRY_NODE_EXPORTER_URL_LINE="DOCKER_REGISTRY_NODE_EXPORTER_URL=$${DOCKER_REGISTRY_NODE_EXPORTER_URL}"
  fi
fi

if [ "$${USE_LOCAL_SSD}" = "true" ]; then
    echo "Using local SSD, preparing"
    mkfs.ext4 -F /dev/disk/by-id/google-local-nvme-ssd-0
    mkdir -p /mnt/executor-pd/
    mount /dev/disk/by-id/google-local-nvme-ssd-0 /mnt/executor-pd
    rsync -xa /var/lib/firecracker/ /mnt/executor-pd
    umount /mnt/executor-pd
    rm -rf /mnt/executor-pd
    mount -o discard,defaults,nobarrier /dev/disk/by-id/google-local-nvme-ssd-0 /var/lib/firecracker
fi

# Write the systemd environment file used by the executor service
cat <<EOF >/etc/systemd/system/executor.env
EXECUTOR_QUEUE_NAME="$${EXECUTOR_QUEUE_NAME}"
EXECUTOR_MAXIMUM_RUNTIME_PER_JOB="$${EXECUTOR_MAXIMUM_RUNTIME_PER_JOB}"
EXECUTOR_MAXIMUM_NUM_JOBS="$${EXECUTOR_MAXIMUM_NUM_JOBS}"
EXECUTOR_JOB_NUM_CPUS="$${EXECUTOR_JOB_NUM_CPUS}"
EXECUTOR_JOB_MEMORY="$${EXECUTOR_JOB_MEMORY}"
EXECUTOR_FIRECRACKER_DISK_SPACE="$${EXECUTOR_FIRECRACKER_DISK_SPACE}"
EXECUTOR_FRONTEND_URL="$${SOURCEGRAPH_EXTERNAL_URL}"
EXECUTOR_FRONTEND_PASSWORD="$${SOURCEGRAPH_EXECUTOR_PROXY_PASSWORD}"
EXECUTOR_NUM_TOTAL_JOBS="$${EXECUTOR_NUM_TOTAL_JOBS}"
EXECUTOR_MAX_ACTIVE_TIME="$${EXECUTOR_MAX_ACTIVE_TIME}"
EXECUTOR_USE_FIRECRACKER="$${EXECUTOR_USE_FIRECRACKER}"
EXECUTOR_DOCKER_REGISTRY_MIRROR_URL="$${EXECUTOR_DOCKER_REGISTRY_MIRROR_URL}"
EXECUTOR_DOCKER_AUTH_CONFIG="$${EXECUTOR_DOCKER_AUTH_CONFIG}"
$${DOCKER_REGISTRY_NODE_EXPORTER_URL_LINE}
EOF

# Enable and start the executor service
systemctl enable executor
systemctl start executor

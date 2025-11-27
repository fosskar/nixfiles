locals {
  # define all containers here
  # add new containers by adding entries to this map
  containers = {
    # example entries - replace with your actual containers
    # vaultwarden = { id = 100, ip = "10.0.0.10" }
    # nextcloud   = { id = 101, ip = "10.0.0.11" }
    # arr         = { id = 102, ip = "10.0.0.12" }
  }
}

resource "proxmox_lxc" "containers" {
  for_each = local.containers

  # container identity
  hostname    = each.key
  vmid        = each.value.id
  target_node = var.proxmox_node

  # nixos template
  ostemplate = var.template_storage

  # resources
  cores  = lookup(each.value, "cores", var.default_cores)
  memory = lookup(each.value, "memory", var.default_memory)

  # storage
  rootfs {
    storage = "local-lvm"
    size    = lookup(each.value, "disk", var.default_disk_size)
  }

  # network configuration
  network {
    name   = "eth0"
    bridge = var.network_bridge
    ip     = "${each.value.ip}/24"
    gw     = var.network_gateway
  }

  # settings
  unprivileged = true
  onboot       = var.start_on_boot
  start        = false # don't auto-start on creation

  # features
  features {
    nesting = true # required for systemd/nixos
  }

  # lifecycle settings
  lifecycle {
    ignore_changes = [
      # ignore changes nixos makes internally
      description,
    ]
  }
}

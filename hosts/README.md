# Hosts config

| Name             | Description                                                                       |
| ---------------- | --------------------------------------------------------------------------------- |
| `desktop`        | main desktop machine                                                              |
| `proxmox-server` | nixos based proxmox server on dedicated hetzner online server                     |
| `k8s`            | k3s multi-node cluster - currently not deployed but worked on 3 hetzner cloud VPS |

Each host imports its own modules inside `configuration.nix`.

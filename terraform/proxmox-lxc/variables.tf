# proxmox connection
variable "proxmox_api_url" {
  description = "proxmox api url (e.g., https://proxmox.example.com:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "proxmox api token id (e.g., user@pam!tokenname)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "proxmox api token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "skip tls verification (set to true for self-signed certificates)"
  type        = bool
  default     = false
}

# infrastructure defaults
variable "proxmox_node" {
  description = "proxmox node name"
  type        = string
  default     = "px-prd1"
}

variable "network_bridge" {
  description = "network bridge for containers"
  type        = string
  default     = "vmbr1"
}

variable "network_gateway" {
  description = "default gateway for containers"
  type        = string
}

variable "template_storage" {
  description = "proxmox storage containing nixos template (e.g., local:vztmpl/nixos.tar.xz)"
  type        = string
}

# container defaults
variable "default_cores" {
  description = "default cpu cores for containers"
  type        = number
  default     = 1
}

variable "default_memory" {
  description = "default memory in mb for containers"
  type        = number
  default     = 512
}

variable "default_disk_size" {
  description = "default disk size for containers"
  type        = string
  default     = "8G"
}

variable "start_on_boot" {
  description = "start containers on proxmox boot"
  type        = bool
  default     = true
}

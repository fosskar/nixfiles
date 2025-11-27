# proxmox lxc container management with terraform

declarative infrastructure for nixos lxc containers on proxmox.

## prerequisites

1. **proxmox api token**
   - create in proxmox ui: datacenter → permissions → api tokens
   - create token for user (e.g., `terraform@pam!terraform`)
   - note down token id and secret
   - assign necessary permissions to the user/token

2. **nixos lxc template**
   - upload nixos lxc template to proxmox storage
   - note the storage path (e.g., `local:vztmpl/nixos-25.05.tar.xz`)

## setup

1. **copy example configuration:**
   ```bash
   cd terraform/proxmox-lxc
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **edit terraform.tfvars with your values:**
   - proxmox api url and credentials
   - node name, network bridge, gateway
   - template storage path

3. **enter development shell:**
   ```bash
   cd /home/simon/code/nixfiles
   nix develop .#terraform
   ```

4. **initialize terraform:**
   ```bash
   cd terraform/proxmox-lxc
   tofu init
   ```

## usage

### adding a new container

1. **edit main.tf** and add container to the `containers` map:
   ```hcl
   locals {
     containers = {
       vaultwarden = { id = 100, ip = "10.0.0.10" }
       nextcloud   = { id = 101, ip = "10.0.0.11" }
     }
   }
   ```

2. **preview changes:**
   ```bash
   tofu plan
   ```

3. **create container:**
   ```bash
   tofu apply
   ```

4. **configure with nixos:**
   ```bash
   cd /home/simon/code/nixfiles
   nixos-rebuild switch --flake .#vaultwarden --target-host root@10.0.0.10
   ```

### importing existing containers

if you have existing containers you want to manage with terraform:

1. **add container to main.tf** with matching id and ip

2. **import into terraform state:**
   ```bash
   tofu import 'proxmox_lxc.containers["vaultwarden"]' px-prd1/lxc/100
   ```

   format: `<node>/lxc/<vmid>`

3. **verify import:**
   ```bash
   tofu plan
   ```

   should show no changes if configuration matches

4. **import all existing containers:**
   ```bash
   # example for multiple containers
   tofu import 'proxmox_lxc.containers["vaultwarden"]' px-prd1/lxc/100
   tofu import 'proxmox_lxc.containers["nextcloud"]' px-prd1/lxc/101
   tofu import 'proxmox_lxc.containers["arr"]' px-prd1/lxc/102
   # ... repeat for all containers
   ```

### customizing container resources

override defaults per container in main.tf:

```hcl
locals {
  containers = {
    vaultwarden = {
      id     = 100
      ip     = "10.0.0.10"
      cores  = 2        # override default
      memory = 2048     # override default
      disk   = "20G"    # override default
    }
  }
}
```

### removing a container

1. **remove from main.tf** containers map

2. **destroy container:**
   ```bash
   tofu apply
   ```

   terraform will detect removal and destroy the container

## workflow

### for new containers
```bash
# 1. add to main.tf
# 2. create with terraform
tofu apply

# 3. configure with nixos
nixos-rebuild switch --flake .#<hostname> --target-host root@<ip>
```

### disaster recovery
if you need to recreate all infrastructure:

```bash
# terraform recreates all containers
tofu apply

# then reapply nixos configs to each
for host in vaultwarden nextcloud arr; do
  nixos-rebuild switch --flake .#$host --target-host root@<ip>
done
```

## notes

- terraform manages infrastructure (cpu, ram, disk, network)
- nixos manages configuration (hostname, services, settings)
- `proxmoxLXC.manageNetwork = false` in nixos config lets nixos control hostname/network after initial setup
- container name in proxmox = hostname set by terraform
- nixos can override hostname internally with `networking.hostName`

## troubleshooting

**import fails:**
- verify container exists: check proxmox ui
- verify correct node name and vmid
- use quotes around resource identifier with brackets

**plan shows unexpected changes:**
- check if nixos modified settings terraform manages
- review `lifecycle.ignore_changes` in main.tf
- verify terraform.tfvars matches actual infrastructure

**api authentication fails:**
- verify api token has correct permissions
- check token hasn't expired
- test with proxmox api manually

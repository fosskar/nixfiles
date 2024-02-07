# Minimal installation Guide for NixOS

## Manual Installation

### 1. Boot with Live USB

- Start interactive login shell as root user

```shell
sudo -i
```

- Change keyboard layout

```shell
loadkeys de
```

### 2. Partitioning and formatting (UEFI)

#### Partitioning

1. Create GPT partition table

```shell
parted /dev/yourDisk -- mklabel gpt
```

2. Add the boot partition. NixOS by default uses the ESP (EFI system partition) as its /boot partition.

```shell
parted /dev/yourDisk -- mkpart ESP fat32 1MB 512MB
parted /dev/yourDisk -- set 1 esp on
```

3. Create root partition

```shell
parted /dev/yourDisk -- mkpart root ext4 512MB 100%
```

4. Create PV

```shell
pvcreate /dev/yourDiskPartition
```

5. Create VG

```shell
vgcreate vgname /dev/yourDiskPartition
```

6. Create LV

```shell
lvcreate -L size -n lvname vgname
```

#### Formatting

1. Format boot partition

```shell
mkfs.fat -F 32 -n boot /dev/youBootPartition
```

2. Format root partition

```shell
mkfs.ext4 -L nixos /dev/vg/lv
```

#### Mount

1. Mount root partition

```shell
mount /dev/disk/by-label/nixos /mnt
```

2. Mount boot partition

```shell
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```


### 3. Generate default nixos configuration

1. Create config

```shell
nixos-generate-config --root /mnt
```

2. Edit config

```shell
nano /mnt/etc/nixos/configuration.nix
```

  2.1. Add user

    ```nix
    oscar
    ```

  2.2. Add nix flake

    ```nix
    nix.settings.experimental-features = "nix-command flakes";
    ```

  2.3. git

    ```nix
    environment.systemPackages = with pkgs; [git];
    ```

### 4. Install NixOS

```shell
nixos-install
```

nixos-install will ask you to set the password for the root user:

```shell
setting root password...
New password: ***
Retype new password: ***
```

### REBOOT

### First Boot

1. Prepare nixos-rebuild
  1.1. git clone

    ```shell
    git clone https://github.com/simonoscr/dotfiles
    ```

    rename to .dotfiles

  1.2. update hardware-configuration.nix

    ```shell
    sudo cp /etc/nixos/hardware-configuration.nix ~/.dotfiles/hosts/voyager/hardware-configuration.nix
    ```

  1.3. copy ssh host keys to server

2. Build

```shell
sudo nixos-rebuild switch --flake .#voyager
```

## DONE

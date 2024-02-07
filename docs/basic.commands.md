# Documentation NixOS, Nix Flake, Standalone Home-Manager

## Update

### Flake Update

Command to update flake input:

```shell
nix flake update
```

## Build with Flake

### NixOS

Build Nixos and use new build directly:

```shell
sudo nixos-rebuild switch --flake .#host
```

Build Nixos and use new build after boot:

```shell
sudo nixos-rebuild boot --flake .#host
```

### Home-Manager

```shell
home-manager switch --flake .#user@host
```

## Updating and Build NixOS

```shell
sudo nixos-rebuild switch --upgrade --flake .#host
```

### Remote Build NixOS

```shell
nixos-rebuild switch --target-host user@host --use-remote-sudo --flake .#host
```

## Programs

### Packages

When you add a package, you're simply making the software available in the user or system environment without additional configuration options provided by modules.

#### NixOS

```nix
environment.systemPackages = with pkgs; [ vim git ];
```

#### Home-Manager

```nix
home.packages = with pkgs; [ vim git ];
```

### Modules

When you use a module, you're not just installing the software; you're also configuring it according to the module's options.

#### NixOS

```nix
services.nginx.enable = true;
```

#### Home-Manager

```nix
programs.git.enable = true;
```

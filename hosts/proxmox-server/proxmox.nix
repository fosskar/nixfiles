{ inputs, ... }:
{
  imports = [ inputs.proxmox-nixos.nixosModules.proxmox-ve ];

  nixpkgs.overlays = [
    inputs.proxmox-nixos.overlays.x86_64-linux
  ];

  services.proxmox-ve = {
    enable = true;
    ipAddress = "5.9.80.138";
  };
}

{ ... }:
{
  imports = [
    ./fwupd.nix
    ./hardware-configuration.nix
    ./bluetooth.nix
    ./amdgpu.nix
    ./wooting.nix
  ];
}

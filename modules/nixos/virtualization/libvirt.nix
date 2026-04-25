{
  flake.modules.nixos.libvirt =
    { pkgs, ... }:
    {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
        };
      };
    };
}

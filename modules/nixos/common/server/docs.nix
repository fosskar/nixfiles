{
  flake.modules.nixos.server =
    { lib, ... }:
    {
      # base/docs.nix disables the rest for all machines; man pages stay on workstations
      documentation.man.enable = lib.mkDefault false;
    };
}

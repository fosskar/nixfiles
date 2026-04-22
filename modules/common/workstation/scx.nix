{
  flake.modules.nixos.workstation =
    {
      lib,
      pkgs,
      ...
    }:
    {
      services.scx = {
        enable = true;
        package = pkgs.scx.rustscheds;
        scheduler = lib.mkDefault "scx_lavd";
      };
    };
}

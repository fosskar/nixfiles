{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      # common documentation settings for all machines
      documentation = {
        enable = lib.mkDefault false;
        doc.enable = lib.mkDefault false;
        info.enable = lib.mkDefault false;
        nixos.enable = lib.mkDefault false;
        # not a restated default: programs.fish would mkDefault-enable this
        man.cache.enable = false;
      };
    };
}

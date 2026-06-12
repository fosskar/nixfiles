{
  # base tuned aspect; profile selection lives in the tuned* variants
  flake.modules.nixos.tuned =
    { lib, ... }:
    {
      services.tuned = {
        enable = true;
        ppdSupport = lib.mkDefault false;
      };

      # nixos-hardware may enable tlp; tuned conflicts with it
      services.tlp.enable = lib.mkForce false;
    };
}

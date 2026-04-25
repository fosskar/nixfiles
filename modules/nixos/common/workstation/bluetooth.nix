{
  flake.modules.nixos.workstation =
    {
      lib,
      options,
      ...
    }:
    let
      hasPreservation = lib.hasAttrByPath [ "preservation" "preserveAt" ] options;
    in
    {
      hardware.bluetooth = {
        enable = lib.mkDefault true;
        powerOnBoot = lib.mkDefault false;
        settings.General.Experimental = lib.mkDefault true;
      };

      preservation = lib.optionalAttrs hasPreservation {
        preserveAt."/persist".directories = [ "/var/lib/bluetooth" ];
      };
    };
}

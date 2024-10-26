{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.services.kde-connect;
in
{
  options.module.services.kde-connect = {
    enable = mkEnableOption "Enable KDE-connect";
  };

  config = mkIf cfg.enable {
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
}

{
  flake.modules.nixos.journaldUpload =
    { config, lib, ... }:
    {
      config = lib.mkIf config.services.journald.upload.enable {
        services.journald.upload.settings.Upload.NetworkTimeoutSec = lib.mkDefault "30s";

        systemd.services.systemd-journal-upload = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
        };
      };
    };
}

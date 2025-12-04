{
  config,
  lib,
  pkgs,
  ...
}:
let
  geolite2-country-db = pkgs.runCommand "geolite2-country" { } ''
    mkdir -p $out
    tar -xzf ${
      pkgs.fetchurl {
        url = "https://github.com/GitSquared/node-geolite2-redist/raw/refs/heads/master/redist/GeoLite2-Country.tar.gz";
        hash = "sha256-W2dnMqkdS1AGaSbxwEmLlZlktXYqslyFNvkBntqEthA=";
      }
    } -C $out --strip-components=1
  '';
in
{
  config = {
    services.pangolin = {
      enable = lib.mkDefault true;

      package = pkgs.callPackage ../../packages/fosrl-pangolin { };

      openFirewall = lib.mkDefault true;
      letsEncryptEmail = lib.mkDefault "letsencrypt.unpleased904@passmail.net";

      settings = {
        app.telemetry = {
          enabled = lib.mkForce false;
        };
        server = {
          maxmind_db_path = "${geolite2-country-db}/GeoLite2-Country.mmdb";
        };
        flags = {
          disable_signup_without_invite = true;
          disable_user_create_org = true;
          enable_integration_api = true;
        };
      };
    };

    # reduce shutdown timeout for faster reboots
    # pangolin doesn't gracefully close websocket tunnels on SIGTERM
    systemd.services.pangolin.serviceConfig = {
      TimeoutStopSec = lib.mkDefault 10;
      KillMode = lib.mkDefault "mixed"; # send SIGTERM to main process, then SIGKILL to all
    };

    # run database migrations before starting pangolin
    systemd.services.pangolin.preStart = lib.mkAfter ''
      ${config.services.pangolin.package}/bin/pangolin-migrate || true
    '';
  };
}

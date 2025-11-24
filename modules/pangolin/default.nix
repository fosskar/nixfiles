{
  config,
  lib,
  ...
}:
{

  config = {
    #nixpkgs.overlays = [
    #  (_final: _prev: {
    #    inherit (inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}) fosrl-gerbil;
    #  })
    #];

    #environment.systemPackages = [
    #  pkgs.fosrl-gerbil
    #];

    services.pangolin = {
      enable = lib.mkDefault true;
      openFirewall = lib.mkDefault true;
      letsEncryptEmail = lib.mkDefault "letsencrypt.unpleased904@passmail.net";

      settings = {
        app.telemetry = {
          enabled = false;
        };
        flags = {
          disable_signup_without_invite = true;
          disable_user_create_org = true;
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

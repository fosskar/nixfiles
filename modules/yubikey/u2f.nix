{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.yubikey;
in
{
  config = lib.mkIf (cfg.enable && cfg.u2f.enable) {
    # uhid kernel module for U2F
    boot.kernelModules = [ "uhid" ];

    # U2F PAM
    security.pam.u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        origin = "pam://yubikey";
        cue = true;
        # interactive removed - conflicts with DMS password input handling
        timeout = 10;
        nouserok = true; # skip u2f if no device present, fall through to password/fprint
      }
      // lib.optionalAttrs (cfg.u2f.authfile != null) {
        inherit (cfg.u2f) authfile;
      };
    };

    # enable U2F for common PAM services
    security.pam.services = {
      login.u2fAuth = lib.mkDefault true;
      sudo.u2fAuth = lib.mkDefault true;
      su.u2fAuth = lib.mkDefault true;
      polkit-1.u2fAuth = lib.mkDefault true;
      greetd.u2fAuth = lib.mkDefault true;
    };

    # extra packages
    environment.systemPackages = with pkgs; [
      yubioath-flutter
    ];
  };
}

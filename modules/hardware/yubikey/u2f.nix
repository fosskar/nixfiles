{ config, ... }:
let
  inherit (config.flake.modules.nixos) yubikey;
in
{
  flake.modules.nixos.yubikeyU2f =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      imports = [ yubikey ];

      clan.core.vars.generators.u2f-keys = {
        share = true;
        files.keys = {
          secret = true;
          neededFor = "users";
        };
        prompts.keys = {
          description = "yubikey u2f pam auth mappings (pamu2fcfg output)";
          type = "multiline";
          persist = true;
        };
        script = "cat $prompts/keys > $out/keys";
      };

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
          authfile = config.clan.core.vars.generators.u2f-keys.files.keys.path;
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

      environment.systemPackages = [ pkgs.yubioath-flutter ];
    };
}

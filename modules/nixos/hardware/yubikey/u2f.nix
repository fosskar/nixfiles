{
  flake.modules.nixos.yubikeyU2f =
    { config, pkgs, ... }:
    {
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
          timeout = 10;
          nouserok = true; # skip u2f if no device present, fall through to password/fprint
          authfile = config.clan.core.vars.generators.u2f-keys.files.keys.path;
        };
      };

      environment.systemPackages = [
        pkgs.yubioath-flutter
      ];
    };
}

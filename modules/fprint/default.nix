{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.fprint;
in
{
  # --- options ---

  options.nixfiles.fprint = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "fingerprint reader support";
    };

    pamServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "login"
        "greetd"
      ];
      description = "pam services to enable fingerprint auth (after password)";
    };
  };

  config = lib.mkIf cfg.enable {
    # --- service ---

    services.fprintd.enable = true;

    # fprint AFTER password (order 13000 > unix at 12900)
    # flow: yubikey → password → fprint
    security.pam.services = lib.genAttrs cfg.pamServices (_service: {
      fprintAuth = true;
      rules.auth.fprintd = {
        order = 13000;
        control = "sufficient";
        modulePath = "${pkgs.fprintd}/lib/security/pam_fprintd.so";
      };
    });

    # --- persistence ---

    nixfiles.persistence.directories = [ "/var/lib/fprint" ];
  };
}

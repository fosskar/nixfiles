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
  options.nixfiles.fprint = {
    enable = lib.mkEnableOption "fingerprint reader support";

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
    services.fprintd.enable = true;

    # persist enrolled fingerprints (impermanence)
    nixfiles.impermanence.directories = lib.mkIf config.nixfiles.impermanence.enable [
      "/var/lib/fprint"
    ];

    # fprint AFTER password (order 13000 > unix at 12900)
    # flow: yubikey → password → fprint
    security.pam.services = lib.genAttrs cfg.pamServices (_service: {
      fprintAuth = false;
      rules.auth.fprintd = {
        order = 13000;
        control = "sufficient";
        modulePath = "${pkgs.fprintd}/lib/security/pam_fprintd.so";
      };
    });
  };
}

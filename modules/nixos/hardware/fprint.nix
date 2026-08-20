{
  flake.modules.nixos.fprint =
    { config, pkgs, ... }:
    {
      services.fprintd.enable = true;

      # flow: yubikey → password → fprint
      # only login: greetd substacks login (useDefaultRules = false upstream),
      # so it inherits this rule
      security.pam.services.login = {
        fprintAuth = true;
        rules.auth.fprintd = {
          # relative to unix because built-in pam rule orders shift whenever
          # upstream inserts rules (autoOrderRules)
          order = config.security.pam.services.login.rules.auth.unix.order + 10;
          control = "sufficient";
          modulePath = "${pkgs.fprintd}/lib/security/pam_fprintd.so";
        };
      };
    };
}

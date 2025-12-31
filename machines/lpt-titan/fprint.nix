{ pkgs, ... }:
{
  services.fprintd = {
    enable = true;
    #tod = {
    #  enable = true;
    #  driver = pkgs.libfprint-2-tod1-vfs0090;
    #};
  };

  # Fingerprint AFTER password (order 13000 > unix at 12900)
  # Flow: YubiKey → Password → Fingerprint
  security.pam.services = {
    login = {
      fprintAuth = false;
      rules.auth.fprintd = {
        order = 13000;
        control = "sufficient";
        modulePath = "${pkgs.fprintd}/lib/security/pam_fprintd.so";
      };
    };
    greetd = {
      fprintAuth = false;
      rules.auth.fprintd = {
        order = 13000;
        control = "sufficient";
        modulePath = "${pkgs.fprintd}/lib/security/pam_fprintd.so";
      };
    };
    i3lock = {
      fprintAuth = false;
      rules.auth.fprintd = {
        order = 13000;
        control = "sufficient";
        modulePath = "${pkgs.fprintd}/lib/security/pam_fprintd.so";
      };
    };
  };
}

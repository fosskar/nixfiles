{lib, ...}: {
  security.sudo.execWheelOnly = true;
  security.pam.services.nginx.setEnvironment = false;
  systemd.services.nginx.serviceConfig = {
    SupplementaryGroups = ["shadow"];
  };
  fonts.fontconfig.enable = false;

  environment = {
    variables.BROWSER = "echo";
    defaultPackages = lib.mkForce []; # no extra default packages are installed
  };

  sound.enable = false;
}

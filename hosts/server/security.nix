{lib, ...}: {
  security.sudo.execWheelOnly = true;
  fonts.fontconfig.enable = false;

  environment = {
    variables.BROWSER = "echo";
    defaultPackages = lib.mkForce []; # no extra default packages are installed
  };

  sound.enable = false;
}

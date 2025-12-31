{ inputs, ... }:
{
  imports = [
    inputs.dms.nixosModules.greeter
  ];

  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/simon";
  };

  # persist greeter state (if impermanence is used)
  environment.persistence."/persist".directories = [
    "/var/lib/dmsgreeter"
  ];
}

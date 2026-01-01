{
  inputs,
  config,
  lib,
  ...
}:
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
  nixfiles.impermanence.directories = lib.mkIf config.nixfiles.impermanence.enable [
    "/var/lib/dmsgreeter"
  ];
}

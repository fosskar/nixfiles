{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = ../home/simon/secrets.yaml;
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
  };

  home.packages = with pkgs; [
    sops
  ];
}

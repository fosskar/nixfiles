{ config, pkgs, ... }:
{
  services = {
    udev.packages = with pkgs; [
      yubikey-personalization
      libu2f-host
    ];
    pcscd.enable = true;
    yubikey-agent.enable = true;
  };

  programs = {
    yubikey-touch-detector.enable = true;
    #ssh.startAgent = true;
  };

  security.pam = {
    #u2f = {
    #  enable = true;
    #  cue = true;
    #  control = "sufficient";
    #  interactive = true;
    #};
    yubico = {
      enable = true;
      debug = true;
      mode = "challenge-response";
      id = [ "29507896" ];
    };
    #services = {
    #  login.u2fAuth = true;
    #  greetd.u2fAuth = true;
    #  sudo.u2fAuth = true;
    #  hyprlock.u2fAuth = true;
    #};
  };

  #users.users.yubikey = {
  #  isNormalUser = true;
  #  extraGroups = [ "wheel" ];
  #  shell = "/run/current-system/sw/bin/bash";
  #};

  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-manager-qt
    yubikey-personalization
    yubikey-personalization-gui
    yubico-piv-tool
    yubioath-flutter
    age-plugin-yubikey
    #pam_u2f
    yubico-pam
  ];
}

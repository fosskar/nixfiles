{ lib, pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      neovim
      btop
      bat
      curl
      dig

      k9s
      argo
      dive
      kubectl
      kubernetes-helm
      cilium-cli
      clusterctl
      skopeo
    ];
    defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
  };
  xdg = {
    icons.enable = lib.mkForce false;
    mime.enable = lib.mkForce false;
    sounds.enable = lib.mkForce false;
    menus.enable = lib.mkForce false;
    autostart.enable = lib.mkForce false;
  };
  fonts.fontconfig.enable = false;
}

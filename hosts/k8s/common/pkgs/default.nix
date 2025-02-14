{ lib, pkgs, ... }:
{
  environment = {
    defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
    systemPackages = with pkgs; [
      tcpdump
      neovim
      vim
      btop
      bat
      btop
      iproute2
      jq
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
  };
}

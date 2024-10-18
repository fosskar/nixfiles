{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    toybox

    # test
    ansible
    virt-manager
    #vagrant
    molecule
    terraform

    ventoy-full

    brave
    libarchive
  ];
}

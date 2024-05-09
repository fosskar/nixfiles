{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    alejandra
    deadnix
    statix
    cachix
  ];
}

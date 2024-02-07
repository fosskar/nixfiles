{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.nix-gaming.nixosModules.steamCompat];

  programs = {
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv = {};
        extraLibraries = pkgs:
          with pkgs; [
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            libkrb5
            keyutils
          ];
      };
      extraCompatPackages = [
        inputs.nix-gaming.packages.${pkgs.system}.proton-ge
      ];
    };
  };
}

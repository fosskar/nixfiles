{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    vkbasalt
  ];

  programs.steam = {
    enable = true;
    extest.enable = true;

    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    # fix gamescope inside steam
    package = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          keyutils
          libkrb5
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
        ];
    };
  };
}

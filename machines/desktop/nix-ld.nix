{ pkgs, ... }:
{
  # delta ships prebuilt binaries that dlopen wayland/vulkan at runtime
  programs.nix-ld.libraries = [
    pkgs.wayland
    pkgs.libxkbcommon
    pkgs.vulkan-loader
    pkgs.libglvnd
    pkgs.fontconfig
    pkgs.freetype
    pkgs.alsa-lib
    pkgs.libgbm
    pkgs.xorg.libX11
    pkgs.xorg.libxcb
    pkgs.xorg.libXcursor
    pkgs.xorg.libXi
    pkgs.xorg.libXrandr
  ];
}

{
  flake.modules.nixos.workstation =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.local.delta ];

      environment.sessionVariables.XKB_CONFIG_ROOT = "${pkgs.xkeyboard_config}/etc/X11/xkb";

      programs.nix-ld.libraries = [
        pkgs.wayland
        pkgs.libxkbcommon
        pkgs.vulkan-loader
        pkgs.libglvnd
        pkgs.fontconfig
        pkgs.freetype
        pkgs.alsa-lib
        pkgs.libgbm
        pkgs.libx11
        pkgs.libxcb
        pkgs.libxcursor
        pkgs.libxi
        pkgs.libxrandr
      ];
    };
}

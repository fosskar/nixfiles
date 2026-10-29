{
  flake.modules.nixos.tern =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.local.tern ];

      # tern updates its copy in ~/.local/opt/tern, so the unpatched binary runs through nix-ld
      programs.nix-ld.enable = true;
      # libraries the binary dlopens at runtime
      programs.nix-ld.libraries = [
        pkgs.libglvnd
        pkgs.vulkan-loader
        pkgs.wayland
        pkgs.libxkbcommon
        pkgs.libxcb
        pkgs.libpulseaudio
        pkgs.pipewire
        pkgs.webkitgtk_4_1
        pkgs.linux-pam
      ];
    };
}

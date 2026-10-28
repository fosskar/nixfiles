{
  # tern (stencil.so) ships a self-updating binary; unpack it to ~/.local/opt and run tern/tern
  flake.modules.nixos.tern =
    { pkgs, ... }:
    {
      programs.nix-ld.enable = true;
      # libraries the binary dlopens at runtime
      programs.nix-ld.libraries = [
        pkgs.libglvnd
        pkgs.vulkan-loader
        pkgs.wayland
        pkgs.libxkbcommon
        pkgs.libxcb
        pkgs.libpulseaudio
        pkgs.linux-pam
      ];
    };
}

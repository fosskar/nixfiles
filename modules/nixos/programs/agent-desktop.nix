{
  flake.modules.nixos.agentDesktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.local.agent-desktop
        # agent-desktop's wayland clipboard shells out to wl-copy and wl-paste
        pkgs.wl-clipboard
      ];

      # owns org.a11y.Bus; without it every accessibility tree comes back empty
      services.gnome.at-spi2-core.enable = true;
    };
}

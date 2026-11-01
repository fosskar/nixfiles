{
  flake.modules.homeManager.herdrApp =
    { lib, pkgs, ... }:
    let
      disableTelemetry = pkgs.writeShellScript "herdr-app-disable-telemetry" ''
        set -eu
        settings="''${XDG_CONFIG_HOME:-$HOME/.config}/herdr-app/settings.json"
        mkdir -p "$(dirname "$settings")"
        [ -e "$settings" ] || echo '{}' > "$settings"
        ${lib.getExe pkgs.jq} '.telemetry = false' "$settings" > "$settings.tmp"
        mv "$settings.tmp" "$settings"
      '';
    in
    {
      home.packages = [ pkgs.local.herdr-app ];

      # the app writes settings.json itself (zoom, theme picker), so nix only
      # forces the telemetry key instead of owning the file
      home.activation.herdrAppTelemetry = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${disableTelemetry}
      '';

      wayland.windowManager.niri.settings.binds."Mod+E" = {
        _props.hotkey-overlay-title = "Open herdr";
        spawn = [
          "focus-or-spawn"
          "herdr-app"
          "herdr-app"
        ];
      };
      programs.umbriel.settings.keybinds."Mod+E" = {
        action = "spawn focus-or-spawn herdr-app herdr-app";
        repeat = false;
      };
    };
}

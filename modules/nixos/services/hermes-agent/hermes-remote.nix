{ inputs, ... }:
{
  flake.modules.nixos.hermesRemote =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.hermes-remote;
      desktopPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
      # the env var HERMES_DESKTOP_REMOTE_URL locks Settings -> Gateways in the
      # app, so seed connection.json once instead; the app migrates it into its
      # connections.json registry and owns it afterwards
      launcher = pkgs.writeShellScriptBin "hermes-desktop-remote" ''
        set -eu
        dir="''${XDG_CONFIG_HOME:-$HOME/.config}/Hermes"
        file="$dir/connection.json"
        if [ ! -e "$file" ]; then
          umask 077
          ${pkgs.coreutils}/bin/mkdir -p "$dir"
          ${pkgs.jq}/bin/jq -n --arg url ${lib.escapeShellArg cfg.url} \
            '{ mode: "remote", remote: { url: $url, authMode: "oauth" }, profiles: {} }' > "$file"
        fi
        exec ${desktopPackage}/bin/hermes-desktop "$@"
      '';
      desktopItem = pkgs.makeDesktopItem {
        name = "hermes-desktop-remote";
        desktopName = "Hermes Desktop";
        comment = "Hermes Agent desktop client";
        exec = "${launcher}/bin/hermes-desktop-remote";
        icon = "${desktopPackage}/share/icons/hicolor/1024x1024/apps/hermes.png";
        categories = [
          "Network"
          "Chat"
        ];
      };
    in
    {
      options.services.hermes-remote = {
        enable = lib.mkEnableOption "remote Hermes desktop client";
        url = lib.mkOption {
          type = lib.types.str;
          example = "https://hermes.example.org";
          description = "Hermes webapp URL the desktop app signs in to with oauth";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          launcher
          desktopItem
        ];
      };
    };
}

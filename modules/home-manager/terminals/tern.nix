{
  # needs programs.nix-ld.enable on the host, see packages/tern/package.nix
  flake.modules.homeManager.tern =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      json = pkgs.formats.json { };
      settingsFile = json.generate "tern-settings.json" config.programs.tern.settings;
    in
    {
      options.programs.tern.settings = lib.mkOption {
        inherit (json) type;
        default = { };
        description = "keys merged into ~/.config/tern/settings.json on every activation";
      };

      config = {
        # tern's own desktop entries and ~/.local/bin/tern skip the launcher and its libraries
        programs.tern.settings.desktop_integration = lib.mkDefault false;

        home.packages = [ pkgs.local.tern ];

        # tern saves its Settings UI changes to settings.json, so merge instead of linking a read-only file
        home.activation.ternSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settings="${config.xdg.configHome}/tern/settings.json"
          current="$settings"
          [ -e "$current" ] || current=${builtins.toFile "empty.json" "{}"}
          merged=$(mktemp)
          ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$current" ${settingsFile} > "$merged"
          run install -Dm600 "$merged" "$settings"
          rm "$merged"
        '';
      };
    };
}

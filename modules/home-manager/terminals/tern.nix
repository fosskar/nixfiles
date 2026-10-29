{
  # needs programs.nix-ld.enable on the host
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
      # tern runs its self-updated copy in ~/.local/opt/tern through nix-ld; keep the system nix-ld libraries
      nixLdLibraryPath = "${lib.makeLibraryPath pkgs.local.tern.runtimeLibs}:/run/current-system/sw/share/nix-ld/lib";
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

        # shells and graphical sessions, so tern finds its libraries however it starts
        home.sessionVariables.NIX_LD_LIBRARY_PATH = nixLdLibraryPath;
        systemd.user.sessionVariables.NIX_LD_LIBRARY_PATH = nixLdLibraryPath;

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

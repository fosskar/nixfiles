{ config, pkgs, ... }:
{
  programs.umbriel.settings = {
    keybinds."Mod+S" = {
      action = "spawn focus-or-spawn steam steam";
      repeat = false;
    };

    # the main file is applied last and would override gamemode.toml, so outputs live in an include.
    # absolute paths: config.toml is a symlink into the nix store
    include = {
      files = [ "${config.xdg.configHome}/umbriel/outputs.toml" ];
      # written by the noctalia displays plugin's game mode
      optional.files = [ "${config.xdg.configHome}/umbriel/gamemode.toml" ];
    };
  };

  xdg.configFile."umbriel/outputs.toml".source =
    (pkgs.formats.toml { }).generate "umbriel-outputs.toml"
      {
        # mirrors kanshi.nix: a changed output section resets kanshi's live mode and position
        # aw3423dwf qd-oled
        output."DP-1" = {
          mode = "3440x1440@165";
          position = [
            0
            0
          ];
          hdr = "on";
          vrr = "disabled";
          # only allows tearing; the gaming feature's window rule requests it
          tearing = true;
        };

        output."HDMI-A-2" = {
          mode = "1920x1080@120";
          position = [
            3440
            (-450)
          ];
          transform = "270";
        };
      };
}

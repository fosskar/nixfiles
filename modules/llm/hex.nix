{ inputs, ... }:
{
  flake.modules.homeManager.hex =
    { lib, options, ... }:
    {
      imports = [ inputs.hex.homeManagerModules.hex ];
      config = lib.mkMerge [
        {
          programs.hex = {
            enable = true;
            autostart = true;
            # terminals such as herdr paste on ctrl+shift+v only
            settings.paste_with_shift = true;
          };
          # niri 26.04 has no org.gnome.Shell GrabAccelerators, so the
          # GlobalShortcuts portal cannot bind; hold mode needs release binds
          # https://redirect.github.com/niri-wm/niri/pull/4744
          wayland.windowManager.niri.settings.binds."Alt+Space" = {
            spawn = [
              "hex"
              "dictation"
              "toggle"
            ];
            _props.hotkey-overlay-title = "Toggle Hex dictation";
          };
        }
        (lib.optionalAttrs (options.programs ? umbriel) {
          programs.umbriel.settings.keybinds."Alt+Space" = {
            action = "spawn hex dictation toggle";
            repeat = false;
          };
        })
      ];
    };
}

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
            # hold the key left of 1 (^ on the de layout) to dictate
            shortcut = "section";
            settings = {
              # terminals such as herdr paste on ctrl+shift+v only
              paste_with_shift = true;
              sound_theme = "soft";
              recording_audio_behavior = "do_nothing";
              indicator_position = "bottom";
              "labs.live_text" = true;
              "labs.vocabulary_biasing" = true;
              "labs.spoken_symbols" = true;
              "labs.appearance_theme" = "dark";
              "labs.live_typing" = true;
              "labs.section_key_alone" = true;
            };
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
          # hex asks the portal for the `section` keysym, which no key types alone
          # on the de layout; the key left of 1 types dead_circumflex there
          programs.umbriel.settings.global_shortcuts."anomaly.hex"."dictation-section" = "dead_circumflex";
        })
      ];
    };
}

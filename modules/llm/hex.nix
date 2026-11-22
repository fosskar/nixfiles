{ inputs, ... }:
{
  flake.modules.homeManager.hex = {
    imports = [ inputs.hex.homeManagerModules.hex ];
    config = {
      programs.hex = {
        enable = true;
        autostart = true;
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
    };
  };
}

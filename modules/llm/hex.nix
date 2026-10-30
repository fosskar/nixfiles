{ inputs, ... }:
{
  flake.modules.homeManager.hex = {
    imports = [ inputs.hex.homeManagerModules.hex ];
    programs.hex = {
      enable = true;
      autostart = true;
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
}

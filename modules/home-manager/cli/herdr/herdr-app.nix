{
  flake.modules.homeManager.herdrApp =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.local.herdr-app ];

      wayland.windowManager.niri.settings.binds."Mod+E" = {
        _props.hotkey-overlay-title = "Open herdr";
        spawn = [
          "focus-or-spawn"
          "herdr-app"
          "herdr-app"
        ];
      };
    };
}

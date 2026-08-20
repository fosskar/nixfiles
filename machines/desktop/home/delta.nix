{ pkgs, ... }:
{
  # delta bundles an unpatched libxkbcommon that looks for /usr/share/X11/xkb
  home.sessionVariables.XKB_CONFIG_ROOT = "${pkgs.xkeyboard_config}/etc/X11/xkb";
}

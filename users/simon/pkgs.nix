{ pkgs, ... }:
{
  home.packages = [
    # desktop apps
    # small channel: signal hard-expires old clients; stay ahead of the cutoff
    pkgs.small.signal-desktop

    pkgs.cinny-desktop

    # media
    pkgs.spotify
    pkgs.imv

    # gui is qt quick; the session's QML2_IMPORT_PATH (per-user profile qml
    # dirs) hides QtQuick.Controls
    (pkgs.symlinkJoin {
      name = "opencloud-desktop";
      paths = [ pkgs.opencloud-desktop ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/opencloud --unset QML2_IMPORT_PATH
      '';
    })
    pkgs.obsidian

    pkgs.ausweisapp
  ];
}

{ lib, pkgs, ... }:
let
  element = pkgs.symlinkJoin {
    name = "element-desktop";
    paths = [ pkgs.element-desktop ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/element-desktop \
        --add-flags "--password-store=gnome-libsecret"
    '';
  };
in
{
  home.packages = [ element ];

  # after noctalia.service (Type=notify), so the tray watcher exists when element registers its icon
  systemd.user.services.element-desktop = {
    Unit = {
      Description = "Element";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "noctalia.service"
      ];
    };
    Service.ExecStart = lib.getExe' element "element-desktop";
    Install.WantedBy = [ "graphical-session.target" ];
  };
}

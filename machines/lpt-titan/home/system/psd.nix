{ pkgs, ... }:
let
  # custom browser definitions for psd
  braveBrowser = pkgs.writeText "brave" ''
    DIRArr[0]="$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser"
    PSNAME="brave"
  '';
  zenBrowser = pkgs.writeText "zen" ''
    DIRArr[0]="$HOME/.zen"
    PSNAME="zen"
    check_suffix=1
  '';

  # patch psd to include custom browsers
  psdWithBrowsers = pkgs.profile-sync-daemon.overrideAttrs (old: {
    installPhase = old.installPhase + ''
      cp ${braveBrowser} $out/share/psd/browsers/brave
      cp ${zenBrowser} $out/share/psd/browsers/zen
    '';
  });
in
{
  services.psd = {
    enable = true;
    package = psdWithBrowsers;
    browsers = [
      "firefox"
      "brave"
      "zen"
    ];
  };
}

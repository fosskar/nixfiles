{ pkgs, ... }:
{
  services = {
    dbus = {
      enable = true;
      packages = with pkgs; [
        gcr
        udisks2
        gnome-keyring
        gnome-settings-daemon
      ];
      implementation = "broker"; # FIXME broker is default now: https://github.com/NixOS/nixpkgs/pull/299812/files#diff-55d37a9071ac2ecf6608be4c1cab8d13fe08842de379d3231ed182e22075042eR42
    };
  };
}

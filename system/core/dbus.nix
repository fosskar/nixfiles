{pkgs, ...}: {
  services = {
    dbus = {
      enable = true;
      packages = with pkgs; [dconf gcr udisks2];
      implementation = "broker"; #FIXME broker is default now: https://github.com/NixOS/nixpkgs/pull/299812/files#diff-55d37a9071ac2ecf6608be4c1cab8d13fe08842de379d3231ed182e22075042eR42
    };

    psd = {
      enable = true;
      resyncTimer = "10m";
    };
  };
}

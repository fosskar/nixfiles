{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.yubikey;
in
{
  config = lib.mkIf (cfg.enable && cfg.lockOnRemove) {
    services.udev.extraRules = ''
      # lock screen when yubikey is unplugged
      ACTION=="remove", \
      ENV{ID_BUS}=="usb", \
      ENV{ID_MODEL_ID}=="0407", \
      ENV{ID_VENDOR_ID}=="1050", \
      ENV{ID_VENDOR}=="Yubico", \
      RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
  };
}

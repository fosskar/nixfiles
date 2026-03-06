# minimal samba share for HP printer "scan to network folder"
# printer only supports SMB — this feeds scans into paperless consume dir
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.paperless;
  consumeDir = config.services.paperless.consumptionDir;
in
{
  options.nixfiles.paperless.samba.enable =
    lib.mkEnableOption "samba share for printer scan-to-paperless";

  config = lib.mkIf (cfg.enable && cfg.samba.enable) {
    # auto-generate samba password for printer
    clan.core.vars.generators.samba-printer = {
      files."password" = { };
      runtimeInputs = with pkgs; [ pwgen ];
      script = ''
        pwgen -s 32 1 | tr -d '\n' > "$out/password"
      '';
    };

    services.samba = {
      enable = true;
      openFirewall = true;
      nmbd.enable = false;
      winbindd.enable = false;
      settings = {
        global = {
          "server string" = "smbnix";
          "server role" = "standalone server";
          security = "user";
          "disable netbios" = "yes";
          "dns proxy" = false;
          "log level" = "0 auth:2";
          logging = "systemd";
          "hosts allow" = "192.168.10.0/24 127.0.0.0/8";
          "hosts deny" = "0.0.0.0/0";
          "map to guest" = "never";
          "load printers" = "no";
          printing = "bsd";
          "printcap name" = "/dev/null";
        };
        scan = {
          path = consumeDir;
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "force user" = "nextcloud";
          "force group" = "nextcloud";
          "create mask" = "0666";
          "directory mask" = "0777";
          comment = "printer scan to paperless";
        };
      };
    };

    # sync samba password from clan var
    systemd.services.samba-passdb-sync = {
      description = "sync printer samba password";
      after = [ "samba-smbd.service" ];
      wants = [ "samba-smbd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail
        pwfile=${config.clan.core.vars.generators.samba-printer.files."password".path}
        [ -e "$pwfile" ] || exit 0

        timeout=15
        while [ "$timeout" -gt 0 ]; do
          [ -f /var/lib/samba/private/secrets.tdb ] && break
          sleep 1
          timeout=$((timeout - 1))
        done
        [ "$timeout" -gt 0 ] || { echo "samba db not ready" >&2; exit 1; }

        password=$(cat "$pwfile")
        ${pkgs.coreutils}/bin/printf "%s\n%s\n" "$password" "$password" | \
          ${lib.getExe' pkgs.samba "smbpasswd"} -s -a paperless >/dev/null
      '';
    };
  };
}

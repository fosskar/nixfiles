{
  flake.modules.nixos.opencloud =
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      localHost = "opencloud.${flake-self.domains.local}";
      officeHost = "collabora.${flake-self.domains.local}";
      collaboraPort = 9980;
      # collabora lists fonts via /usr/share/fonts; coolwsd-systemplate-setup
      # copies that dir into the jail systemplate, so provide it via bind mount.
      collaboraFonts = pkgs.symlinkJoin {
        name = "collabora-fonts";
        paths = [
          pkgs.liberation_ttf
          pkgs.dejavu_fonts
          pkgs.carlito
          pkgs.caladea
        ];
      };
    in
    {
      services.collabora-online = {
        enable = true;
        port = collaboraPort;
        aliasGroups = [ { host = "https://${localHost}:443"; } ];
        settings = {
          net.listen = "loopback";
          ssl.enable = false;
          ssl.termination = true;
        };
      };

      fileSystems."/usr/share/fonts/collabora" = {
        device = "${collaboraFonts}/share/fonts";
        fsType = "none";
        options = [ "bind" ];
      };

      services.opencloud.environment = {
        OC_ADD_RUN_SERVICES = "collaboration";
        COLLABORATION_APP_NAME = "CollaboraOnline";
        COLLABORATION_APP_PRODUCT = "Collabora";
        COLLABORATION_APP_ADDR = "https://${officeHost}";
        COLLABORATION_WOPI_SRC = "https://${localHost}";
        # collabora doesn't support WOPI proof keys
        COLLABORATION_APP_PROOF_DISABLE = "true";
      };

      # collaboration service refuses startup when document server unreachable
      systemd.services.opencloud = {
        after = [ "coolwsd.service" ];
        wants = [ "coolwsd.service" ];
      };

      # coolwsd with net.proto=all + net.listen=loopback binds [::1] only
      services.caddy.virtualHosts.${officeHost}.extraConfig = ''
        reverse_proxy http://[::1]:${toString collaboraPort}
      '';

      services.gatus.settings.endpoints = [
        {
          name = "Collabora";
          url = "https://${officeHost}/hosting/discovery";
          group = "Files";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };
}

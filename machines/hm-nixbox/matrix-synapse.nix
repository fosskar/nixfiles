{
  config,
  lib,
  pkgs,
  ...
}:
{
  # auto-generate registration shared secret using clan.core.vars
  clan.core.vars.generators."matrix-synapse" = {
    files."registration_shared_secret" = { };
    runtimeInputs = with pkgs; [
      coreutils
      pwgen
    ];
    script = ''
      echo -n "$(pwgen -s 32 1)" > "$out"/registration_shared_secret
    '';
  };

  services.matrix-synapse = {
    enable = true;

    settings = {
      server_name = "matrix.simonoscar.me";
      public_baseurl = "https://matrix.simonoscar.me/";

      # secret copied to /run with correct ownership before start
      registration_shared_secret_path = "/run/synapse-registration-shared-secret";

      # default listener already binds to 127.0.0.1:8008 with client+federation
      # just disable compression since traefik handles it
      listeners = lib.mkForce [
        {
          bind_addresses = [ "127.0.0.1" ];
          port = 8008;
          tls = false;
          type = "http";
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = false;
            }
          ];
        }
      ];

      # database - postgresql via unix socket
      database = {
        name = "psycopg2";
        args = {
          user = "matrix-synapse";
          database = "matrix-synapse";
          host = "/run/postgresql";
        };
      };

      # TURN servers for voice/video calls
      turn_uris = [
        "turn:turn.matrix.org?transport=udp"
        "turn:turn.matrix.org?transport=tcp"
      ];

      # registration disabled - use CLI with shared secret
      enable_registration = false;

      # url previews
      url_preview_enabled = true;
      url_preview_ip_range_blacklist = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "100.64.0.0/10"
        "192.0.0.0/24"
        "169.254.0.0/16"
        "::1/128"
        "fe80::/10"
        "fc00::/7"
      ];

      # federation
      trusted_key_servers = [
        { server_name = "matrix.org"; }
      ];

      # disable telemetry
      report_stats = false;

      # serve /.well-known/matrix/server for federation
      serve_server_wellknown = true;

      # media storage
      max_upload_size = "100M";
    };
  };

  # postgresql - synapse requires C collation
  clan.core.postgresql.users.matrix-synapse = { };
  clan.core.postgresql.databases.matrix-synapse = {
    create.options = {
      TEMPLATE = "template0";
      LC_COLLATE = "C";
      LC_CTYPE = "C";
      ENCODING = "UTF8";
      OWNER = "matrix-synapse";
    };
    restore.stopOnRestore = [ "matrix-synapse.service" ];
  };

  # copy secret with correct ownership for synapse to read
  systemd.services.matrix-synapse.serviceConfig.ExecStartPre = lib.mkBefore [
    "+${pkgs.coreutils}/bin/install -o matrix-synapse -g matrix-synapse ${
      lib.escapeShellArg
        config.clan.core.vars.generators."matrix-synapse".files."registration_shared_secret".path
    } /run/synapse-registration-shared-secret"
  ];
}

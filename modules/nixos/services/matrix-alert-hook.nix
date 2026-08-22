_: {
  flake.modules.nixos.matrixAlertHook =
    { config, pkgs, ... }:
    let
      listenAddress = "127.0.0.1";
      listenPort = 9088;
      messageTemplate = pkgs.writeText "matrix-alert-message.html.tmpl" ''
        <p>
        {{ if eq .Status "firing" }}🔥 <strong>FIRING</strong>{{ else if eq .Status "resolved" }}✅ <strong>RESOLVED</strong>{{ else }}<strong>{{ .Status }}</strong>{{ end }}
        — <strong>{{ .Labels.alertname }}</strong>
        </p>
        {{ with .Annotations.summary }}<p>{{ . }}</p>{{ end }}
        {{ with .Annotations.description }}<p>{{ . }}</p>{{ end }}
        {{ with .GeneratorURL }}<p><a href="{{ . }}">Open alert in Grafana</a></p>{{ end }}
      '';
    in
    {
      clan.core.vars.generators.matrix-alert-hook = {
        prompts.access-token = {
          description = "Matrix access token for @alerts:fosskar.de";
          type = "hidden";
        };
        files.env.secret = true;
        script = ''
          printf 'MX_TOKEN=%s\n' "$(cat "$prompts/access-token")" > "$out/env"
        '';
      };

      systemd.services.matrix-alert-hook = {
        description = "Forward alert webhooks to Matrix";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          HTTP_ADDRESS = listenAddress;
          HTTP_PORT = toString listenPort;
          MX_HOMESERVER = "https://matrix.fosskar.eu";
          MX_ID = "@alerts:fosskar.de";
          MX_ROOMID = "!V9AbNBfBhczqH2WRQr_0wAT6q6ycq7tfSFuw9nM7t3s";
          MX_MSG_TEMPLATE = messageTemplate;
        };
        serviceConfig = {
          DynamicUser = true;
          EnvironmentFile = config.clan.core.vars.generators.matrix-alert-hook.files.env.path;
          ExecStart = "${pkgs.matrix-hook}/bin/matrix-hook";
          Restart = "on-failure";
          RestartSec = 5;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
        };
      };
    };
}

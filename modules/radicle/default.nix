{
  config,
  lib,
  pkgs,
  ...
}:
let
  explorerPort = 8090;

  explorer = pkgs.radicle-explorer.withConfig {
    preferredSeeds = [
      {
        hostname = "radicle.fosskar.eu";
        port = 443;
        scheme = "https";
      }
    ];
  };
in
{
  clan.core.vars.generators.radicle = {
    files."ssh-private-key" = {
      secret = true;
      owner = "radicle";
      group = "radicle";
      mode = "0600";
    };
    files."ssh-public-key".secret = false;
    runtimeInputs = [ pkgs.openssh ];
    script = ''
      ssh-keygen -t ed25519 -N "" -f "$out/ssh-private-key" -C "radicle@${config.networking.hostName}"
      ssh-keygen -y -f "$out/ssh-private-key" > "$out/ssh-public-key"
    '';
  };

  services.radicle = {
    enable = true;

    privateKey = config.clan.core.vars.generators.radicle.files."ssh-private-key".path;
    publicKey = config.clan.core.vars.generators.radicle.files."ssh-public-key".path;

    node.openFirewall = true;

    httpd = {
      enable = true;
      listenAddress = "127.0.0.1";
      nginx = {
        serverName = "radicle";
        listen = [
          {
            addr = "0.0.0.0";
            port = explorerPort;
          }
        ];
        forceSSL = false;
        enableACME = false;
      };
    };

    settings.node.externalAddresses = [ "nixworker.s:8776" ];
  };

  # serve radicle-explorer static files, override default api-only proxy on /

  services.nginx.virtualHosts."radicle" = {
    root = lib.mkForce "${explorer}";
    locations."/" = {
      proxyPass = lib.mkForce null;
      tryFiles = "$uri $uri/ /index.html =404";
      extraConfig = ''
        expires 1h;
        add_header Cache-Control "public, immutable";
      '';
    };
    locations."/api/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.radicle.httpd.listenPort}";
      recommendedProxySettings = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ explorerPort ];
}

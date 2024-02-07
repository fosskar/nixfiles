{
  config,
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.kanidm];
  sops.secrets.a2FuaWRtUm9vdENBLmNydA = {
    mode = "0600";
    owner = "kanidm";
  };
  sops.secrets.a2FuaWRtUm9vdENBLmtleQ = {
    mode = "0600";
    owner = "kanidm";
  };

  services.kanidm = {
    enableServer = true;
    serverSettings = {
      tls_chain = config.sops.secrets.a2FuaWRtUm9vdENBLmNydA.path;
      tls_key = config.sops.secrets.a2FuaWRtUm9vdENBLmtleQ.path;
      bindaddress = "0.0.0.0:3013";
      origin = "https://kanidm.space";
      domain = "kanidm.space";
      trust_x_forward_for = true;
    };
    enableClient = true;
    clientSettings = {
      uri = config.services.kanidm.serverSettings.origin;
      verify_ca = true;
      verify_hostnames = true;
    };
  };

  services.nginx = {
    virtualHosts."kanidm.space" = {
      #forceSSL = true;
      #sslCertificate = config.sops.secrets.a2FuaWRtUm9vdENBLmNydA.path;
      #sslCertificateKey = config.sops.secrets.a2FuaWRtUm9vdENBLmtleQ.path;
      # Allow using self-signed certs to satisfy kanidm's requirement for TLS connections.
      extraConfig = ''
        proxy_ssl_verify off;
      '';
      locations."/" = {
        proxyPass = "https://${config.services.kanidm.serverSettings.bindaddress}";
      };
      listen = [
        {
          addr = "192.168.178.91";
          port = 443;
        }
      ];
    };
  };
}

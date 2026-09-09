{
  flake.modules.nixos.netbirdAuthelia =
    # authelia as external oidc connector for the netbird embedded idp.
    # the connector itself is registered once through the management api
    # (POST /api/identity-providers) with the plain secret from this
    # generator; its id fixes the redirect uri below.
    {
      config,
      flake-self,
      pkgs,
      ...
    }:
    let
      netbirdHost = "nb.${flake-self.domains.public}";
      connectorId = "dagr55um0qvcpng6m7f0";
    in
    {
      clan.core.vars.generators.netbird-oidc = {
        files = {
          "client-secret" = { };
          "client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
        };
        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
        ];
        script = ''
          SECRET=$(pwgen -s 64 1)
          echo -n "$SECRET" > "$out/client-secret"
          authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/client-secret-hash"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "netbird";
          client_name = "NetBird";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.netbird-oidc.files."client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          redirect_uris = [
            "https://${netbirdHost}/oauth2/callback/${connectorId}"
            "https://${netbirdHost}/oauth2/logout/callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];
    };
}

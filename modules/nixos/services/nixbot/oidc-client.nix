# authelia-side half of nixbot oidc login: client registration + secret hash.
# nixbot itself runs on another machine (default.nix); import this on the
# authelia host.
{
  flake.modules.nixos.nixbotOidc =
    {
      flake-self,
      config,
      pkgs,
      ...
    }:
    let
      publicHost = "nixbot.${flake-self.domains.public}";
    in
    {
      config = {
        # same shared generator as default.nix; hash owned by authelia for
        # the {{ secret }} config template
        clan.core.vars.generators.nixbot-oidc = {
          share = true;
          files."oauth-client-secret" = { };
          files."oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
          runtimeInputs = [
            pkgs.pwgen
            pkgs.authelia
          ];
          script = ''
            SECRET=$(pwgen -s 64 1)
            echo -n "$SECRET" > "$out/oauth-client-secret"
            authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          '';
        };

        services.authelia.instances.main.settings.identity_providers.oidc.clients = [
          {
            client_id = "nixbot";
            client_name = "Nixbot";
            client_secret = "{{ secret \"${
              config.clan.core.vars.generators.nixbot-oidc.files."oauth-client-secret-hash".path
            }\" }}";
            public = false;
            consent_mode = "implicit";
            authorization_policy = "users";
            redirect_uris = [ "https://${publicHost}/auth/oidc/callback" ];
            scopes = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            # nixbot sends no PKCE (auth.py has no code_challenge) and
            # authenticates via client_secret_basic
            token_endpoint_auth_method = "client_secret_basic";
          }
        ];
      };
    };
}

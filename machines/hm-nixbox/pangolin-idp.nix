{
  config,
  pkgs,
  ...
}:
{
  # generate pangolin oauth secret
  clan.core.vars.generators.pangolin = {
    files."oauth-client-secret-hash" = {
      owner = "authelia-main";
      group = "authelia-main";
    };
    files."oauth-client-secret" = { };

    runtimeInputs = with pkgs; [
      pwgen
      authelia
    ];
    script = ''
      SECRET=$(pwgen -s 64 1)
      authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
      echo -n "$SECRET" > "$out/oauth-client-secret"
    '';
  };

  # claims policy to include claims in id_token (pangolin requirement)
  services.authelia.instances.main.settings.identity_providers.oidc.claims_policies.pangolin = {
    id_token = [
      "groups"
      "email"
      "email_verified"
      "preferred_username"
      "name"
    ];
  };

  # register oidc client with authelia
  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_id = "pangolin";
      client_name = "Pangolin";
      client_secret = "{{ secret \"${
        config.clan.core.vars.generators.pangolin.files."oauth-client-secret-hash".path
      }\" }}";
      claims_policy = "pangolin";
      public = false;
      consent_mode = "implicit";
      require_pkce = true;
      pkce_challenge_method = "S256";
      redirect_uris = [
        "https://pangolin.fosskar.eu/auth/idp/2/oidc/callback"
      ];
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
      scopes = [
        "openid"
        "profile"
        "email"
        "groups"
      ];
    }
  ];
}

{
  pkgs,
  ...
}:
{
  # generate pangolin oauth secret
  clan.core.vars.generators.pangolin = {
    files."oauth-client-secret-hash" = { };
    files."oauth-client-secret" = { };

    runtimeInputs = with pkgs; [
      pwgen
      authelia
    ];
    script = ''
      SECRET=$(pwgen -s 64 1)
      authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 > "$out/oauth-client-secret-hash"
      echo -n "$SECRET" > "$out/oauth-client-secret"
    '';
  };

  # register oidc client with authelia
  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_id = "pangolin";
      client_name = "Pangolin";
      client_secret = "$pbkdf2-sha512$310000$86J7nqg93a.FxsgeBJpyxw$JlSY4iDkcyqFhbni4D1/ykjLQJvQer9V26w6OwSvrS7uL3IS8HkkFBgn02DJrm/IXSAqVw5F9HFzUlp7cYeeMQ";
      public = false;
      authorization_policy = "two_factor";
      consent_mode = "implicit";
      redirect_uris = [
        "https://pangolin.fosskar.eu/auth/idp/1/oidc/callback"
      ];
      scopes = [
        "openid"
        "profile"
        "email"
      ];
    }
  ];
}

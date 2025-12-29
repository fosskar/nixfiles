{
  config,
  pkgs,
  ...
}:
{
  # auto-generate jwt secret using clan.core.vars
  clan.core.vars.generators.lldap = {
    files."jwt-secret" = {
      secret = true;
      mode = "0444";
    };
    runtimeInputs = with pkgs; [
      coreutils
      pwgen
    ];
    script = ''
      pwgen -s 64 1 | tr -d '\n' > "$out/jwt-secret"
    '';
  };

  services.lldap = {
    enable = true;

    settings = {
      ldap_base_dn = "dc=nixbox,dc=local";

      ldap_host = "127.0.0.1";
      ldap_port = 3890;

      http_host = "127.0.0.1";
      http_port = 17170;
      http_url = "https://ldap.osscar.me";

      ldap_user_pass_file = config.sops.secrets."admin-password".path;
      jwt_secret_file = config.clan.core.vars.generators.lldap.files."jwt-secret".path;

      force_ldap_user_pass_reset = "always";
    };
  };
}

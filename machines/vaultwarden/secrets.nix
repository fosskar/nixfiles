{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets = {
    vaultwarden-envs = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/vaultwarden/envs.age";
    };
    vaultwarden-oidc-client-id = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/vaultwarden/oidc-client-id.age";
    };
    vaultwarden-oidc-client-secret = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/vaultwarden/oidc-client-secret.age";
    };
  };
}

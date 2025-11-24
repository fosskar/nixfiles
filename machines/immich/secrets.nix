{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets = {
    immich-envs = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/immich/envs.age";
    };
    immich-oauth-client-id = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/immich/oauth-client-id.age";
    };
    immich-oauth-client-secret = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/immich/oauth-client-secret.age";
    };
  };
}

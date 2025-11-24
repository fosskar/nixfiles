{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets = {
    paperless-admin-password = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/paperless/admin-password.age";
    };
    paperless-envs = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/paperless/envs.age";
    };
  };
}

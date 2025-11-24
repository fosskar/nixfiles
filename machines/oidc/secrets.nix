{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets = {
    envs = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/pocket-id/envs.age";
    };
  };
}

{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets = {
    homepage-envs = {
      rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/homepage/envs.age";
    };
  };
}

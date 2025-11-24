{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets.newt-envs.rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/newt/envs.age";
}

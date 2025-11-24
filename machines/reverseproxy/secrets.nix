{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets.pangolin-envs.rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/pangolin/envs.age";
}

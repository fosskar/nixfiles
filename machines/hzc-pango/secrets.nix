{ inputs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  age.secrets.envs-hzx.rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/pangolin/envs-hzx.age";
}

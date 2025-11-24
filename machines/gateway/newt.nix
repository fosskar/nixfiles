{
  config,
  ...
}:
{
  # now this service definition block refers to the module as defined in
  # inputs.nixos-unstable!
  services.newt = {
    enable = true;
    environmentFile = config.age.secrets.newt-envs.path;
  };
}

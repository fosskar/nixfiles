{
  config,
  ...
}:
{
  services.newt = {
    enable = true;
    environmentFile = config.sops.secrets."newt.env".path;
  };
}

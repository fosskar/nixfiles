{
  config,
  pkgs,
  ...
}:
{
  services.newt = {
    enable = true;
    package = pkgs.custom-fosrl-newt;
    environmentFile = config.sops.secrets."newt.env".path;
  };
}

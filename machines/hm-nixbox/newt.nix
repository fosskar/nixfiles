{
  config,
  pkgs,
  ...
}:
{
  services.newt = {
    enable = true;
    package = pkgs.callPackage ../../packages/fosrl-newt { };
    environmentFile = config.sops.secrets."newt.env".path;
  };
}

{
  flake.modules.nixos.server =
    { pkgs, ... }:
    {
      services.postgresql.package = pkgs.postgresql_18;
    };
}

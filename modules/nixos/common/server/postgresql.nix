{
  flake.modules.nixos.server =
    { lib, pkgs, ... }:
    {
      services.postgresql = {
        package = pkgs.postgresql_18;

        # sized for the postgres hosts (nixbox 62 GiB, nixworker 92 GiB, both
        # on ssd); databases are under 1 GB and zfs arc caches the rest
        settings = {
          shared_buffers = lib.mkDefault "2GB";
          effective_cache_size = lib.mkDefault "16GB";
          maintenance_work_mem = lib.mkDefault "512MB";
          work_mem = lib.mkDefault "16MB";
          random_page_cost = lib.mkDefault 1.1;
        };
      };
    };
}

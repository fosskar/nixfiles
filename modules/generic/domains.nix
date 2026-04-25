{
  flake.modules.generic.domains =
    { lib, ... }:
    {
      options.domains = lib.mkOption {
        type = lib.types.submodule {
          options = {
            local = lib.mkOption {
              type = lib.types.str;
              default = "nx3.eu";
              description = "local/home-network DNS domain.";
            };

            public = lib.mkOption {
              type = lib.types.str;
              default = "fosskar.eu";
              description = "public internet DNS domain.";
            };
          };
        };
        default = { };
        description = "global DNS domains used by service modules.";
      };
    };
}

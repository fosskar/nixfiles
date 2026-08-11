{
  self,
  inputs,
  config,
  ...
}:
{
  flake.clan = {
    inherit self;
    specialArgs = {
      inherit inputs;
      nflib = config.flake.lib;
      flake-self = self;
    };

    meta = {
      name = "nixfiles";
      domain = "s";
      description = "personal nix infrastructure";
    };

    #vars.settings.age.postQuantum = true;

    secrets.age.plugins = [
      "age-plugin-yubikey"
    ];

    inventory.machines = {
      "nixbox" = {
        tags = [
          "server"
          "home"
        ];
      };

      "gateway" = {
        tags = [
          "server"
          "hetzner"
        ];
      };

      "lpt-titan" = {
        tags = [
          "laptop"
          "home"
          "workstation"
        ];
      };

      "nixworker" = {
        tags = [
          "server"
          "home"
          "remote-builder"
        ];
      };

      "desktop" = {
        tags = [
          "workstation"
          "home"
        ];
      };
    };
  };
}

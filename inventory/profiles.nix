{
  inputs,
  config,
  ...
}:
let
  # only declared by the srvos profiles, so it cannot live in modules.nixos.base
  srvosFlake = {
    srvos.flake = inputs.self;
  };
in
{
  flake.clan.inventory.instances = {
    base-common = {
      module.name = "importer";
      roles.default = {
        tags = [ "nixos" ];
        extraModules = [
          config.flake.modules.nixos.base
          config.flake.modules.nixos.clanMachineId
        ];
      };
    };

    server-common = {
      module.name = "importer";
      roles.default = {
        tags = [ "server" ];
        extraModules = [
          inputs.srvos.nixosModules.server
          srvosFlake
          config.flake.modules.nixos.server
        ];
      };
    };

    workstation-common = {
      module.name = "importer";
      roles.default = {
        tags = [ "workstation" ];
        extraModules = [
          inputs.srvos.nixosModules.desktop
          srvosFlake
          config.flake.modules.nixos.homeManager
          config.flake.modules.nixos.workstation
          config.flake.modules.nixos.nixAccessTokens
          config.flake.modules.nixos.yubikey
          config.flake.modules.nixos.niri
        ];
      };
    };

    laptop-common = {
      module.name = "importer";
      roles.default = {
        tags = [ "laptop" ];
        extraModules = [
          config.flake.modules.nixos.laptop
          config.flake.modules.nixos.fprint
          config.flake.modules.nixos.yubikeyLockOnRemove
        ];
      };
    };
  };
}

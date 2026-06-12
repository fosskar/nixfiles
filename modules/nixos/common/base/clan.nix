{
  flake.modules.nixos.clanMachineId =
    { lib, ... }:
    {
      clan.core.settings.machine-id.enable = true;

      # store-backed /etc/machine-id breaks nix-optimise (EXDEV); see https://git.clan.lol/clan/clan-core/issues/7556
      environment.etc.machine-id.enable = lib.mkForce false;
    };
}

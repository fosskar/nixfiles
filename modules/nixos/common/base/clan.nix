{
  flake.modules.nixos.clanMachineId =
    { config, lib, ... }:
    {
      clan.core.settings.machine-id.enable = true;

      # store-backed /etc/machine-id breaks nix-optimise (EXDEV); see https://git.clan.lol/clan/clan-core/issues/7556.
      # the etc overlay keeps the file in its own image instead of the store
      environment.etc.machine-id.enable = lib.mkIf (!config.system.etc.overlay.enable) (
        lib.mkForce false
      );
    };
}

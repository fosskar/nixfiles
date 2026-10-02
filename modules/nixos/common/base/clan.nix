{
  flake.modules.nixos.clanMachineId =
    { config, lib, ... }:
    {
      clan.core.settings.machine-id.enable = true;

      # store-backed /etc/machine-id breaks nix-optimise (EXDEV); see https://git.clan.lol/clan/clan-core/issues/7556.
      # the etc overlay keeps default-mode entries as store symlinks too; an
      # explicit mode puts the file into the etc image instead
      environment.etc.machine-id =
        if config.system.etc.overlay.enable then { mode = "0444"; } else { enable = lib.mkForce false; };
    };
}

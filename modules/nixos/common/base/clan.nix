{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      clan.core.settings.machine-id.enable = true;

      # clan.core.settings.machine-id creates /etc/machine-id in the nix store,
      # causing systemd to mount a tmpfs overlay (for writability), which breaks
      # nix-optimise (EXDEV cross-device link). disable the store-backed file;
      # systemd-machine-id-setup writes a real /etc/machine-id at boot, and on
      # ephemeral-root hosts the preservation module restores it via symlink.
      # clan's kernel cmdline still works.
      environment.etc.machine-id.enable = lib.mkForce false;
    };
}

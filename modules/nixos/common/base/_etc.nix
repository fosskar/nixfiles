# disabled via _ prefix (import-tree skips it): etc.overlay too experimental
# for now; re-enable by renaming to etc.nix when revisiting nixos-init
{
  flake.modules.nixos.base = {
    # mutable upperdir (default); immutable is a later step
    system.etc.overlay.enable = true;
  };
}

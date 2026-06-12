{
  flake.modules.nixos.base = _: {
    system = {
      # upgrade manually, review changelogs; unattended upgrades risk silent breakage
      autoUpgrade.enable = false;
    };
  };
}

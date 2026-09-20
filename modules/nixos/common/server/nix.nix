{
  flake.modules.nixos.server = {
    services.harmonia.gc = {
      enable = true;
      automatic = true;
      deleteOlderThan = "14d";
      keepRecent = "1d";
    };
  };
}

{
  flake.modules.nixos.server = {
    services.harmonia.gc = {
      enable = true;
      automatic = true;
      deleteOlderThan = "7d";
      keepRecent = "1d";
    };
  };
}

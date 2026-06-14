{
  flake.modules.homeManager.nixIndex =
    # pre-built index for nix-locate, comma (`, htop`), and command-not-found suggestions
    {
      inputs,
      ...
    }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      programs.nix-index-database.comma.enable = true;
    };
}

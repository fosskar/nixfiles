_: {
  flake.modules.homeManager.rbw =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.rbw
        pkgs.pinentry-gnome3
      ];
    };
}

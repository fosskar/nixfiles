_: {
  flake.modules.homeManager.psd =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.psd;
    in
    {
      # psd only reads browser definitions from its own share dir, so browser
      # aspects add theirs here and get them copied into the package
      options.services.psd.extraBrowsers = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = "psd browser definitions by name; each is also added to services.psd.browsers.";
      };

      config.services.psd = {
        enable = true;
        package = pkgs.profile-sync-daemon.overrideAttrs (old: {
          installPhase =
            old.installPhase
            + lib.concatStrings (
              lib.mapAttrsToList (name: text: ''
                cp ${pkgs.writeText name text} $out/share/psd/browsers/${name}
              '') cfg.extraBrowsers
            );
        });
        browsers = lib.attrNames cfg.extraBrowsers;
      };
    };
}

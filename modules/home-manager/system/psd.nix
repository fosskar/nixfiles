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
      # features add theirs here and get them copied into the package
      options.services.psd.extraBrowsers = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = "psd browser definitions by name; each is also added to services.psd.browsers.";
      };

      # psd mounts fuse-overlayfs during the first sync; home-manager runs it in
      # the oneshot psd-resync.service, whose cgroup kill unmounts the overlay
      config.systemd.user.services.psd.Service.ExecStartPost =
        "${lib.getExe' cfg.package "profile-sync-daemon"} resync";

      # sd-switch starts psd-resync.service in its own job, ahead of psd.service;
      # the pid file exists only after psd.service has done the first sync
      config.systemd.user.services.psd-resync.Unit.ConditionPathExists = "%t/psd.pid";

      # a stop/start on switch unsyncs under a running browser, which then
      # finds an empty config dir and creates a new profile
      config.systemd.user.services.psd.Unit.X-SwitchMethod = "keep-old";

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

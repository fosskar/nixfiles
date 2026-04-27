{
  self,
  mylib,
  ...
}:
{
  imports = [
    self.modules.nixos.btrfs
    self.modules.nixos.systemdBoot
    self.modules.nixos.tunedServerPowersave
    self.modules.nixos.buildbotMaster
    self.modules.nixos.buildbotWorker
    self.modules.nixos.radicle
  ]
  ++ (mylib.scanPaths ./. { });

  services.buildbot-nix.master = {
    domain = "buildbot.fosskar.eu";
    admins = [ "fosskar" ];
    gitea = {
      oauthId = "a7b24f2c-1291-4566-970c-d39b869f0a35";
      topic = null;
      repoAllowlist = [
        "fosskar/nixfiles"
        "fosskar/nixwork"
        "fosskar/wiki"
      ];
    };
  };

  srvos.boot.consoles = [ "tty0" ];

  # zed remote server binary runs over ssh; nix-ld helps with dynamic linker deps.
  programs.nix-ld.enable = true;
}

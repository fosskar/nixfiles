_: {
  nixfiles.buildbot = {
    master = {
      enable = true;
      domain = "buildbot.fosskar.eu";
      admins = [ "fosskar" ];
      codeberg = {
        oauthId = "a7b24f2c-1291-4566-970c-d39b869f0a35";
        topic = null;
        repoAllowlist = [
          "fosskar/nixfiles"
          "fosskar/nixwork"
          "fosskar/wiki"
        ];
      };
    };
    worker.enable = true;
  };
}

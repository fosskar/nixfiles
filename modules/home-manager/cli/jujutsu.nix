_: {
  flake.modules.homeManager.jujutsu =
    _:
    let
      email = "117449098+fosskar@users.noreply.github.com";
      name = "fosskar";
    in
    {
      programs = {
        jjui.enable = true;
        jujutsu = {
          enable = true;
          settings = {
            user = {
              inherit email name;
            };

            ui.editor = "nvim";
            git = {
              sign-on-push = true;
            };
            remotes = {
              origin = {
                auto-track-bookmarks = "glob:*";
              };
            };
            # signing.key is set per-user; backend/behavior are common
            # "keep" so local rewrites (fetch, snapshot, rebase) never reach for
            # the yubikey through the agent relay; sign-on-push still signs.
            signing = {
              backend = "ssh";
              behavior = "keep";
            };
            snapshot = {
              max-new-file-size = 16000000; # ~16mb
              auto-update-stale = true;
            };
          };
        };
      };
    };
}

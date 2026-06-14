_: {
  flake.modules.homeManager.jujutsu =
    _:
    let
      email = "fosskar.educated493@passmail.net";
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

            ui = {
              default-command = "log"; # or status. log is more verboses
              editor = "nvim";
              graph = {
                style = "curved";
              };
            };
            git = {
              sign-on-push = true;
            };
            fetch = {
              prune = true;
            };
            remotes = {
              origin = {
                auto-track-bookmarks = "glob:*";
              };
            };
            # signing.key is set per-user; backend/behavior are common
            signing = {
              backend = "ssh";
              behavior = "keep";
            };
            snapshot = {
              max-new-file-size = 16000000; # ~16mb
            };
            init = {
              default_branch = "main";
            };
          };
        };
      };
    };
}

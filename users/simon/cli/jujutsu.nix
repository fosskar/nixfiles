_:
let
  email = "fosskar.educated493@passmail.net";
  name = "fosskar";
in
{
  imports = [
  ];

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
        signing = {
          backend = "ssh";
          behavior = "keep";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA";
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
}

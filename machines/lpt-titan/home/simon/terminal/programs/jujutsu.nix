{
  config,
  ...
}:
let

  email = "fosskar@noreply.codeberg.org";
  name = "fosskar";
in
{

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        inherit email name;
      };
      ui = {
        default-command = "log"; # or status. log is more verboses
        diff-editor = ":builtin";
        diff-formatter = ":git";
        #merge-editor = "meld";
        editor = "nvim";
        graph = {
          style = "curved";
        };
        pager = "delta";
        paginate = "auto";
      };
      git = {
        sign-on-push = true;
      };
      remotes.origin = {
        auto-track-bookmarks = "glob:*";
      };
      signing = {
        backend = "ssh";
        behavior = "drop";
        key = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      init = {
        default_branch = "main";
      };
      merge-tools = {
        difft = {
          program = "difft";
          diff-args = [
            "--color=always"
            "$left"
            "$right"
          ];
        };
      };
    };
  };
}

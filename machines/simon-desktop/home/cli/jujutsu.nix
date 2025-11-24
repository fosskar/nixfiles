_:
let
  email = "smonoscr@noreply.codeberg.org";
  name = "smonoscr";
in
{
  imports = [
  ];

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
        auto-local-bookmark = true;
        sign-on-push = true;
      };
      signing = {
        backend = "gpg";
        behavior = "drop";
        key = "F6EBB0BC75FCBBA7";
      };
      snapshot = {
        max-new-file-size = 16000000; # ~16mb
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

_:
let
  email = "osscar.unheard025@passmail.net";
  name = "osscar";
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
        aliases = {
          dm = [
            "describe"
            "-m"
          ];
          cm = [
            "commit"
            "-m"
          ];
          bs = [
            "bookmark"
            "set"
          ];
          fetch = [
            "git"
            "fetch"
          ];
          push = [
            "git"
            "push"
          ];
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
          backend = "ssh";
          behavior = "drop";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA";
          #key = "1394DCC0EC169ED4";
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
  };
}

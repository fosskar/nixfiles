{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.module.terminal.programs.jujutsu;

  email = "smonoscr@noreply.codeberg.org";
  name = "smonoscr";
in
{
  imports = [
  ];
  options.module.terminal.programs.jujutsu = {
    enable = mkEnableOption "Enable jujutsu";
  };

  config = mkIf cfg.enable {

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
  };
}

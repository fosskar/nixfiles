{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.module.terminal.programs.jujutsu;

  email = "13078509-simonoscr@users.noreply.gitlab.com";
  name = "simonoscr";
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
          editor = "zeditor --wait";
        };
        signing = {
          backend = "ssh";
          sign-all = true;
          key = "${config.home.homeDirectory}/.ssh/id_ed25519";
        };
        init = {
          default_branch = "main";
        };
      };
    };
  };
}

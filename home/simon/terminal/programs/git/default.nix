{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.module.terminal.programs.git;

  email = "smonoscr@noreply.codeberg.org";
  name = "smonoscr";
in
{
  imports = [
    ./aliases.nix
    ./ignores.nix
  ];
  options.module.terminal.programs.git = {
    enable = mkEnableOption "Enable git";
  };

  config = mkIf cfg.enable {

    programs.git = {
      enable = true;
      lfs.enable = true;
      #riff.enable = true; # maybe?
      delta = {
        enable = true;
        options.dark = true;
      };
      extraConfig = {
        branch = {
          autosetuprebase = "always";
          sort = "-committerdate";
        };
        column.ui = "auto";
        commit.verbose = true;
        color.ui = true;
        core.editor = "nvim";
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };
        fetch = {
          all = true;
          prune = true;
          pruneTags = true;
          auto = true;
          parallel = 10;
        };
        github.user = name;
        help.autoCorrect = "prompt";
        init.defaultBranch = "main";
        merge.conflictstyle = "zdiff3";
        push = {
          autoSetupRemote = true;
          default = "simple";
          followTags = true;
        };
        pull.rebase = true;
        rebase = {
          autoSquash = true;
          autoStash = true;
          updateRefs = true;
        };
        tag.sort = "version:refname";
      };
      userEmail = email;
      userName = name;

      signing = {
        key = "${config.home.homeDirectory}/.ssh/id_ed25519";
        format = "ssh";
        signByDefault = true;
      };
    };
  };
}

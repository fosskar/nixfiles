{
  mylib,
  ...
}:
let
  email = "smonoscr@noreply.codeberg.org";
  name = "smonoscr";
in
{
  imports = mylib.scanPaths ./. { };

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
      key = "F6EBB0BC75FCBBA7";
      format = "openpgp";
      signByDefault = true;
    };
  };
}

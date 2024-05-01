{config, ...}: let
  email = "117449098+simonoscr@users.noreply.github.com";
  name = "simonoscr";
in {
  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      color.ui = true;
      core.editor = "nvim";
      credential.helper = "store";
      github.user = name;
      push.autoSetupRemote = true;
      diff.colorMoved = "default";
      gpg.format = "ssh";
      commit.gpgsign = true;
      pull.rebase = true;
      init.defaultBranch = "main";
      url = {
        "ssh://git@gitlab.com:simonoscr" = {
          insteadOf = "https://gitlab.com/simonoscr";
        };
      };
    };
    userEmail = email;
    userName = name;

    aliases = {
      ad = "add";
      br = "branch";
      co = "commit";
      ca = "commit --amend";
      cm = "commit -m";
      checko = "checkout";
      d = "diff";
      ds = "diff --staged";
      p = "push";
      pf = "push --force-with-lease";
      pl = "pull";
      l = "log";
      r = "rebase";
      ss = "status --short";
      st = "status";
      forgor = "commit --amend --no-edit";
      graph = "log --all --decorate --graph --oneline";
      oops = "checkout --";
      fe = "fetch";
      sw = "switch";
    };

    ignores = [".DS_Store" "*.swp" "Thumbs.db" ".idea/" ".vscode/" ".vscodium/"];

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
  };
}

{ config, ... }:
let
  email = "13078509-simonoscr@users.noreply.gitlab.com";
  name = "simonoscr";
in
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    delta = {
      enable = true;
      options.dark = true;
    };
    extraConfig = {
      color.ui = true;
      core.editor = "nvim";
      github.user = name;
      push.autoSetupRemote = true;
      diff.colorMoved = "default";
      gpg = {
        format = "ssh";
        #ssh.allowedSignersFile = config.home.homeDirectory + "/" + config.xdg.configFile."git/allowed_signers".target;
      };
      commit.gpgsign = true;
      pull.rebase = true;
      init.defaultBranch = "main";
      fetch.auto = true;
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

    ignores = [
      ".DS_Store"
      "*.swp"
      "Thumbs.db"
      ".idea"
      ".vscode"
      ".vscodium"
      ".direnv"
      "pre-commit-config.yaml"
      "results"
    ];

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519";
      signByDefault = true;
    };
  };
  #xdg.configFile."git/allowed_signers".text = ''
  #  ${cfg.userEmail} namespaces="git" ${key}
  #'';
}

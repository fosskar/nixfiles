{ config, ... }:
let
  email = "214-simon.siedl@users.noreply.gitlab.mecom.de";
  name = "Simon Siedl";
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
      push.autoSetupRemote = true;
      diff.colorMoved = "default";
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
      };
      commit.gpgsign = true;
      pull.rebase = true;
      init.defaultBranch = "main";
      auto.fetch = true;
      #core.sshCommand = "ssh -i ${config.home.homeDirectory}/.ssh/id_rsa";
    };

    userEmail = email;
    #userEmail = config.sops.templates."workmail".content;
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
      key = "${config.home.homeDirectory}/.ssh/id_rsa";
      signByDefault = true;
    };
  };
  #home.sessionVariables.SSH_AUTH_SOCK = "$HOME/.ssh/agent.sock";
  #home.activationScripts.sshAgent = ''
  #  if [ ! -S $SSH_AUTH_SOCK ]; then
  #    eval $(ssh-agent -a $SSH_AUTH_SOCK)
  #  fi
  #  ssh-add ${config.home.homeDirectory}/.ssh/id_rsa
  #'';
}

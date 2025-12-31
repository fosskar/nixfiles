{
  programs.git = {
    settings.alias = {
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
  };
}

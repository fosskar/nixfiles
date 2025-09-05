_: {
  programs.git = {
    aliases = {
      a = "add --patch";
      ad = "add";

      b = "branch";
      ba = "branch -a";
      bd = "branch --delete";
      bD = "branch -D";

      c = "commit";
      ca = "commit --amend";
      cm = "commit -m";
      co = "checkout";
      cb = "checkout --branch";
      cl = "clone";
      d = "diff";
      ds = "diff --staged";
      h = "show";
      p = "push";
      pf = "push --force-with-lease";
      pl = "pull";
      l = "log";
      r = "rebase";
      s = "status --short --branch";
      st = "status --short --branch";
      ss = "status";
      sta = "stash";
      stc = "stash clear";
      forgor = "commit --amend --no-edit";
      graph = "log --all --decorate --graph --oneline";
      oops = "checkout --";
      f = "fetch";
      sw = "switch";
    };
  };
}

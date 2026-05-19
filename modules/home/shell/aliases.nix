_: {
  flake.modules.homeManager.shellAliases = _: {
    home.shellAliases = {
      # qol
      mp = "mkdir -p";
      fcd = "cd $(find -type d | fzf)";
      cls = "clear";
      ll = "ls -lah -color";
      la = "ls -A -color";
      grep = "grep --color";
      gpg = "gpg --pinentry-mode loopback";

      # system
      sc = "sudo systemctl";
      jc = "sudo journalctl";
      scu = "systemctl --user ";
      jcu = "journalctl --user";

      # cli
      g = "git";
      h = "helm";
      d = "docker";
      p = "podman";
      z = "zeditor";

      # nav
      ".." = "cd ..";
      "..." = "cd ../../";
      "...." = "cd ../../../";
      "....." = "cd ../../../../";
      "......" = "cd ../../../../../";
    };
  };
}

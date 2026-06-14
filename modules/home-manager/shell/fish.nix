_: {
  flake.modules.homeManager.fish = _: {
    programs.fish = {
      enable = true;

      functions = {
        # jj: commit, bookmark set main, push
        jjp = ''
          jj commit -m "$argv[1]" && jj bookmark set main -r @- && jj git push
        '';

        # git: add, commit, push
        gp = ''
          git add -A && git commit -m "$argv[1]" && git push
        '';
      };

      interactiveShellInit = ''
        set fish_greeting
      '';
    };
  };
}

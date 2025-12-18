{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
    ];

    functions = {
      run = ''
        set pkgname $argv[1]
        set appname $argv[1]
        if test (count $argv) -gt 1
          set appname $argv[2]
        end
        nix-shell -p "$pkgname" --run "$appname"
      '';

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
}

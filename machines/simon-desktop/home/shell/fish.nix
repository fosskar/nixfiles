_: {
  programs.fish = {
    enable = true;

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
      # Disable the greeting message.
      set fish_greeting

      # color input
      set fish_color_command green
      set fish_color_normal brwhite
      set fish_color_param brwhite
      set fish_color_option cyan
      set fish_color_quote yellow

      set -x COLORTERM truecolor
      set -x TERM xterm-256color
    '';
  };
}

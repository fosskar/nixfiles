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
    };

    interactiveShellInit = ''
      # Disable the greeting message.
      set fish_greeting
    '';
  };
}

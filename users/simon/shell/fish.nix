{ pkgs, lib, ... }:
{
  home.activation.configure-tide = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.fish}/bin/fish -c "tide configure --auto --style=Lean --prompt_colors='True color' --show_time=No --lean_prompt_height='Two lines' --prompt_connection=Solid --prompt_connection_andor_frame_color=Dark --prompt_spacing=Sparse --icons='Few icons' --transient=No"
  '';

  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "tide";
        inherit (pkgs.fishPlugins.tide) src;
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

      # override tide nix_shell to show $name instead of just "impure"
      _tide_item_nix_shell = ''
        if set -q IN_NIX_SHELL
          if set -q name[1]
            _tide_print_item nix_shell $tide_nix_shell_icon' ' $name
          else
            _tide_print_item nix_shell $tide_nix_shell_icon' ' $IN_NIX_SHELL
          end
        end
      '';

      _tide_item_jj = ''
        if jj root --quiet &>/dev/null
          set info (jj log -r@ -n1 --no-graph --color never -T 'separate(" ", bookmarks.join(","), change_id.shortest(), if(empty, "", "*"))')
          _tide_print_item jj $info
        else if git rev-parse --git-dir &>/dev/null
          set branch (git branch --show-current 2>/dev/null; or git rev-parse --short HEAD)
          set dirty (test -n "$(git status --porcelain)" && echo " *")
          _tide_print_item git $branch$dirty
        end
      '';
    };

    interactiveShellInit = ''
      set fish_greeting

      set tide_left_prompt_items pwd jj newline character

      set tide_pwd_color_anchors brgreen
      set tide_pwd_color_dirs green
      set tide_pwd_color_truncated_dirs brblack

      set tide_jj_bg_color normal
      set tide_jj_color brmagenta

      set fish_color_command green
    '';
  };
}

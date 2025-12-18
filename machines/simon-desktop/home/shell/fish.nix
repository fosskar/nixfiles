{ pkgs, ... }:
{
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

      # tide prompt item for jujutsu (minimal)
      _tide_item_jj = ''
        jj root --quiet &>/dev/null || return 1

        set -l jj_info (jj log -r@ -n1 --no-graph --color never -T '
          separate("",
            change_id.shortest(4),
            if(bookmarks, " " ++ bookmarks.join(" ")),
            if(conflict, " !"),
            if(divergent, " ~"),
            if(!empty, " *"),
          )
        ')
        _tide_print_item jj "" "$jj_info"
      '';

      # override git to skip if in jj repo (colocated)
      _tide_item_git = ''
        # skip git if we're in a jj repo
        jj root --quiet &>/dev/null && return 1

        # call original git logic
        command -q git || return 1
        git branch --show-current 2>/dev/null | read -l branch || return 1

        set -l git_info $branch

        # check for dirty state
        if not git diff --quiet 2>/dev/null
          set git_info "$git_info *"
        end

        _tide_print_item git " " "$git_info"
      '';
    };

    interactiveShellInit = ''
      set fish_greeting

      # tide config (universal vars already set, -g for reference)
      set -g tide_left_prompt_items pwd git jj newline character
      set -g tide_jj_bg_color normal
      set -g tide_jj_color 875fd7
      set -g tide_pwd_color_dirs 3a8a3a
      set -g tide_pwd_color_anchors 5fd700
    '';
  };
}

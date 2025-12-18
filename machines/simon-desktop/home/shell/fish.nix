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

      # jj prompt item
      _tide_item_jj = /* fish */ ''
        if not command -sq jj; or not jj root --quiet &>/dev/null
          return 1
        end

        set jj_info (jj log -r@ -n1 --ignore-working-copy --no-graph --color never -T '
          change_id.shortest() ++ " " ++
          if(empty, "e", "d") ++
          if(conflict, "c", "") ++
          if(divergent, "v", "") ++
          if(hidden, "h", "")
        ' | string trim)

        set change_id (echo $jj_info | cut -d" " -f1)
        set flags (echo $jj_info | cut -d" " -f2)

        _tide_print_item jj $tide_jj_icon' ' (
            set_color brblack; echo -ns '['
            set_color white; echo -ns '@'
            set_color $tide_jj_color; echo -ns $change_id
            if string match -q '*d*' $flags
                set_color yellow; echo -ns ' *'
            else
                set_color green; echo -ns ' o'
            end
            if string match -q '*c*' $flags
                set_color red; echo -ns ' !'
            end
            if string match -q '*v*' $flags
                set_color yellow; echo -ns ' ~'
            end
            if string match -q '*h*' $flags
                set_color brblack; echo -ns ' ?'
            end
            set_color brblack; echo -ns ']'
        )
      '';

      # override git to skip when in jj repo (prefer jj)
      _tide_item_git = /* fish */ ''
        # skip if in jj repo
        if command -sq jj; and jj root --quiet &>/dev/null
          return 1
        end

        # original tide git logic
        if git branch --show-current 2>/dev/null | string shorten -"$tide_git_truncation_strategy"m$tide_git_truncation_length | read -l location
            git rev-parse --git-dir --is-inside-git-dir | read -fL gdir in_gdir
            set location $_tide_location_color$location
        else if test $pipestatus[1] != 0
            return
        else if git tag --points-at HEAD | string shorten -"$tide_git_truncation_strategy"m$tide_git_truncation_length | read location
            git rev-parse --git-dir --is-inside-git-dir | read -fL gdir in_gdir
            set location '#'$_tide_location_color$location
        else
            git rev-parse --git-dir --is-inside-git-dir --short HEAD | read -fL gdir in_gdir location
            set location @$_tide_location_color$location
        end

        if test -d $gdir/rebase-merge
            if not path is -v $gdir/rebase-merge/{msgnum,end}
                read -f step <$gdir/rebase-merge/msgnum
                read -f total_steps <$gdir/rebase-merge/end
            end
            test -f $gdir/rebase-merge/interactive && set -f operation rebase-i || set -f operation rebase-m
        else if test -d $gdir/rebase-apply
            if not path is -v $gdir/rebase-apply/{next,last}
                read -f step <$gdir/rebase-apply/next
                read -f total_steps <$gdir/rebase-apply/last
            end
            if test -f $gdir/rebase-apply/rebasing
                set -f operation rebase
            else if test -f $gdir/rebase-apply/applying
                set -f operation am
            else
                set -f operation am/rebase
            end
        else if test -f $gdir/MERGE_HEAD
            set -f operation merge
        else if test -f $gdir/CHERRY_PICK_HEAD
            set -f operation cherry-pick
        else if test -f $gdir/REVERT_HEAD
            set -f operation revert
        else if test -f $gdir/BISECT_LOG
            set -f operation bisect
        end

        test $in_gdir = true && set -l _set_dir_opt -C $gdir/..
        set -l stat (git $_set_dir_opt --no-optional-locks status --porcelain 2>/dev/null)
        string match -qr '(0|(?<stash>.*))\n(0|(?<conflicted>.*))\n(0|(?<staged>.*))
(0|(?<dirty>.*))\n(0|(?<untracked>.*))(\n(0|(?<behind>.*))\t(0|(?<ahead>.*)))?' \
            "$(git $_set_dir_opt stash list 2>/dev/null | count
            string match -r ^UU $stat | count
            string match -r ^[ADMR] $stat | count
            string match -r ^.[ADMR] $stat | count
            string match -r '^\?\?' $stat | count
            git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null)"

        if test -n "$operation$conflicted"
            set -g tide_git_bg_color $tide_git_bg_color_urgent
        else if test -n "$staged$dirty$untracked"
            set -g tide_git_bg_color $tide_git_bg_color_unstable
        end

        _tide_print_item git $_tide_location_color$tide_git_icon' ' (set_color white; echo -ns $location
            set_color $tide_git_color_operation; echo -ns ' '$operation ' '$step/$total_steps
            set_color $tide_git_color_upstream; echo -ns ' ⇣'$behind ' ⇡'$ahead
            set_color $tide_git_color_stash; echo -ns ' *'$stash
            set_color $tide_git_color_conflicted; echo -ns ' ~'$conflicted
            set_color $tide_git_color_staged; echo -ns ' +'$staged
            set_color $tide_git_color_dirty; echo -ns ' !'$dirty
            set_color $tide_git_color_untracked; echo -ns ' ?'$untracked)
      '';
    };

    interactiveShellInit = ''
      set fish_greeting

      set -x tide_character_color brgreen
      set -x tide_character_color_failure brred
      set -x tide_character_icon \u276f
      set -x tide_character_vi_icon_default \u276e
      set -x tide_character_vi_icon_replace \u25b6
      set -x tide_character_vi_icon_visual V

      set -x tide_cmd_duration_bg_color normal
      set -x tide_cmd_duration_color brblack
      set -x tide_cmd_duration_decimals 0
      set -x tide_cmd_duration_icon
      set -x tide_cmd_duration_threshold 3000

      set -x tide_context_always_display false
      set -x tide_context_bg_color normal
      set -x tide_context_color_default yellow
      set -x tide_context_color_root bryellow
      set -x tide_context_color_ssh yellow
      set -x tide_context_hostname_parts 1

      set -x tide_direnv_bg_color normal
      set -x tide_direnv_bg_color_denied normal
      set -x tide_direnv_color yellow
      set -x tide_direnv_color_denied brred
      set -x tide_direnv_icon \u25bc

      set -x tide_git_bg_color normal
      set -x tide_git_bg_color_unstable normal
      set -x tide_git_bg_color_urgent normal
      set -x tide_git_color_branch brgreen
      set -x tide_git_color_conflicted brred
      set -x tide_git_color_dirty yellow
      set -x tide_git_color_operation brred
      set -x tide_git_color_staged yellow
      set -x tide_git_color_stash brgreen
      set -x tide_git_color_untracked brblue
      set -x tide_git_color_upstream brgreen
      set -x tide_git_icon
      set -x tide_git_truncation_length 24
      set -x tide_git_truncation_strategy

      set -x tide_jobs_bg_color normal
      set -x tide_jobs_color green
      set -x tide_jobs_icon \uf013
      set -x tide_jobs_number_threshold 1000

      set -x tide_private_mode_bg_color normal
      set -x tide_private_mode_color brwhite
      set -x tide_private_mode_icon \U000f05f9

      set -x tide_prompt_add_newline_before true
      set -x tide_prompt_color_frame_and_connection brblack
      set -x tide_prompt_color_separator_same_color brblack
      set -x tide_prompt_icon_connection \u2500
      set -x tide_prompt_min_cols 34
      set -x tide_prompt_pad_items false
      set -x tide_prompt_transient_enabled false

      set -x tide_left_prompt_frame_enabled false
      set -x tide_left_prompt_items pwd jj git newline character
      set -x tide_left_prompt_prefix
      set -x tide_left_prompt_separator_diff_color " "
      set -x tide_left_prompt_separator_same_color " "
      set -x tide_left_prompt_suffix " "

      set -x tide_right_prompt_frame_enabled false
      set -x tide_right_prompt_items status cmd_duration context jobs direnv bun node python rustc java php pulumi ruby go gcloud kubectl distrobox toolbox terraform aws nix_shell crystal elixir zig
      set -x tide_right_prompt_prefix " "
      set -x tide_right_prompt_separator_diff_color " "
      set -x tide_right_prompt_separator_same_color " "
      set -x tide_right_prompt_suffix

      set -x tide_pwd_bg_color normal
      set -x tide_pwd_color_anchors brgreen
      set -x tide_pwd_color_dirs green
      set -x tide_pwd_color_truncated_dirs brblack
      set -x tide_pwd_icon
      set -x tide_pwd_icon_home
      set -x tide_pwd_icon_unwritable \uf023
      set -x tide_pwd_markers .bzr .citc .git .hg .jj .node-version .python-version .ruby-version .shorten_folder_marker .svn .terraform bun.lockb Cargo.toml composer.json CVS go.mod package.json build.zig

      set -x tide_shlvl_bg_color normal
      set -x tide_shlvl_color yellow
      set -x tide_shlvl_icon \uf120
      set -x tide_shlvl_threshold 1

      set -x tide_status_bg_color normal
      set -x tide_status_bg_color_failure normal
      set -x tide_status_color green
      set -x tide_status_color_failure red
      set -x tide_status_icon \u2714
      set -x tide_status_icon_failure \u2718

      set -x tide_vi_mode_bg_color_default normal
      set -x tide_vi_mode_bg_color_insert normal
      set -x tide_vi_mode_bg_color_replace normal
      set -x tide_vi_mode_bg_color_visual normal
      set -x tide_vi_mode_color_default brblack
      set -x tide_vi_mode_color_insert cyan
      set -x tide_vi_mode_color_replace green
      set -x tide_vi_mode_color_visual yellow
      set -x tide_vi_mode_icon_default D
      set -x tide_vi_mode_icon_insert I
      set -x tide_vi_mode_icon_replace R
      set -x tide_vi_mode_icon_visual V

      set -x tide_aws_bg_color normal
      set -x tide_aws_color yellow
      set -x tide_aws_icon \uf270

      set -x tide_bun_bg_color normal
      set -x tide_bun_color brwhite
      set -x tide_bun_icon \U000f0cd3

      set -x tide_crystal_bg_color normal
      set -x tide_crystal_color brwhite
      set -x tide_crystal_icon \ue62f

      set -x tide_distrobox_bg_color normal
      set -x tide_distrobox_color brmagenta
      set -x tide_distrobox_icon \U000f01a7

      set -x tide_docker_bg_color normal
      set -x tide_docker_color brblue
      set -x tide_docker_default_contexts default colima
      set -x tide_docker_icon \uf308

      set -x tide_elixir_bg_color normal
      set -x tide_elixir_color magenta
      set -x tide_elixir_icon \ue62d

      set -x tide_gcloud_bg_color normal
      set -x tide_gcloud_color brblue
      set -x tide_gcloud_icon \U000f02ad

      set -x tide_go_bg_color normal
      set -x tide_go_color brcyan
      set -x tide_go_icon \ue627

      set -x tide_java_bg_color normal
      set -x tide_java_color yellow
      set -x tide_java_icon \ue256

      set -x tide_kubectl_bg_color normal
      set -x tide_kubectl_color blue
      set -x tide_kubectl_icon \U000f10fe

      set -x tide_nix_shell_bg_color normal
      set -x tide_nix_shell_color brblue
      set -x tide_nix_shell_icon \uf313

      set -x tide_node_bg_color normal
      set -x tide_node_color green
      set -x tide_node_icon \ue24f

      set -x tide_os_bg_color normal
      set -x tide_os_color normal
      set -x tide_os_icon \uf313

      set -x tide_php_bg_color normal
      set -x tide_php_color blue
      set -x tide_php_icon \ue608

      set -x tide_pulumi_bg_color normal
      set -x tide_pulumi_color yellow
      set -x tide_pulumi_icon \uf1b2

      set -x tide_python_bg_color normal
      set -x tide_python_color cyan
      set -x tide_python_icon \U000f0320

      set -x tide_ruby_bg_color normal
      set -x tide_ruby_color red
      set -x tide_ruby_icon \ue23e

      set -x tide_rustc_bg_color normal
      set -x tide_rustc_color red
      set -x tide_rustc_icon \ue7a8

      set -x tide_terraform_bg_color normal
      set -x tide_terraform_color magenta
      set -x tide_terraform_icon \U000f1062

      set -x tide_time_bg_color normal
      set -x tide_time_color brblack
      set -x tide_time_format

      set -x tide_toolbox_bg_color normal
      set -x tide_toolbox_color magenta
      set -x tide_toolbox_icon \ue24f

      set -x tide_zig_bg_color normal
      set -x tide_zig_color yellow
      set -x tide_zig_icon \ue6a9

      set -x tide_jj_bg_color normal
      set -x tide_jj_color brmagenta

      set -x fish_color_command green
      set -x fish_color_error red
      set -x fish_color_param cyan
      set -x fish_color_quote yellow
      set -x fish_color_autosuggestion brblack
      set -x fish_color_comment brblack
      set -x fish_color_operator white
      set -x fish_color_redirection white
      set -x fish_color_end white
      set -x fish_color_escape magenta
      set -x fish_color_valid_path --underline
    '';
  };
}

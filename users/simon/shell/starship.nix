{ config, lib, ... }:
let
  inherit (config) theme;
in
{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;

    settings = {
      format = lib.concatStrings [
        "[╭─](bright-black) $all"
        "$fill "
        "$kubernetes"
        "$terraform"
        "$package"
        "$nix_shell"
        "[─╮](bright-black)"
        "$line_break"
        "$status"
        "$jobs"
        "[╰─](bright-black)$character"
      ];
      right_format = lib.concatStrings [
        "$cmd_duration"
        "[─╯](bright-black)"
      ];
      add_newline = true;

      cmd_duration = {
        format = "[$duration](${theme.dark.semantic.warning}) ";
      };

      directory = {
        style = theme.dark.accent.primary;
      };

      # jj and git integration
      custom = {
        jj = {
          description = "jujutsu vcs status";
          when = "jj --ignore-working-copy root";
          symbol = "󰘬 ";
          command = "jj log -r@ --no-graph --ignore-working-copy --color=never -T 'change_id.shortest()'";
          format = "[$symbol$output](${theme.ansi.normal.magenta}) ";
        };

        git_branch = {
          when = "git rev-parse --git-dir 2>/dev/null && ! jj --ignore-working-copy root 2>/dev/null";
          command = "git branch --show-current 2>/dev/null || git rev-parse --short HEAD";
          symbol = " ";
          format = "[$symbol$output](${theme.ansi.normal.magenta}) ";
          description = "only show git branch if not in a jj repo";
        };
      };

      # disable built-in git modules, using custom modules instead
      git_branch.disabled = true;
      git_status.disabled = true;
      git_commit.disabled = true;

      kubernetes = {
        disabled = false;
        symbol = "󱃾 ";
        format = "[$symbol$context](${theme.ansi.normal.blue}) ";
      };

      nix_shell = {
        symbol = "󱄅 ";
        format = "[$symbol(\($name\))](${theme.ansi.normal.blue}) ";
      };

      character = {
        success_symbol = "[❯](${theme.dark.accent.primary})";
        error_symbol = "[❯](${theme.dark.semantic.error})";
      };

      fill = {
        symbol = "─";
        style = "bright-black";
      };
    };
  };
}

_: {
  flake.modules.homeManager.starship =
    {
      self,
      config,
      lib,
      ...
    }:
    let
      theme = self.themes.${self.theme};
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
          command_timeout = 2000;

          cmd_duration = {
            format = "[$duration](${theme.dark.semantic.warning}) ";
          };

          directory = {
            style = theme.dark.accent.primary;
          };

          # jj and git integration: one command, one process chain per prompt
          custom.vcs = {
            description = "jj change id, or git branch outside jj repos";
            when = true;
            shell = [ "sh" ];
            command = ''
              jj log -r@ --no-graph --ignore-working-copy --color=never -T '"󰘬 " ++ change_id.shortest()' 2>/dev/null \
                || { b=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) && printf ' %s' "$b"; }
            '';
            format = "([$output](${theme.ansi.normal.magenta}) )";
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
    };
}

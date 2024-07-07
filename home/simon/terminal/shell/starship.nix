{ config, lib, ... }:
{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    settings = {
      format = lib.concatStrings [
        "$all"
        "$cmd_duration"
        "$fill "
        "$kubernetes"
        "$terraform"
        "$package"
        "$nix_shell"
        "$line_break"
        "$status"
        "$jobs"
        "$character"
      ];
      add_newline = true;
      character = {
        success_symbol = "[󱞪](bold green)";
        error_symbol = "[󱞪](bold red)";
        vicmd_symbol = "[](bold yellow)";
      };

      cmd_duration = {
        format = "[$duration]($style) ";
      };

      directory = {
        style = "bold green";
        format = "[  $path]($style) ";
      };

      hostname = {
        ssh_only = true;
      };

      kubernetes = {
        disabled = false;
        symbol = "󱃾 ";
        format = "[$symbol$context]($style) ";
      };

      nix_shell = {
        symbol = " ";
        format = "[$symbol(\($name\))]($style) ";
        heuristic = true;
      };

      fill = {
        symbol = "-";
      };
    };
  };
}

{ config, lib, ... }:
with lib;

let
  cfg = config.module.terminal.shell.starship;
in

{
  options.module.terminal.shell.starship = {
    enable = mkEnableOption "Enable starship";
  };

  config = mkIf cfg.enable {
    home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

    programs.starship = {
      enable = true;

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
          format = "[\\[$duration\\]]($style) ";
        };

        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
          format = "[  $path]($style) ";
          style = "bold green";
          disabled = false;
          truncation_symbol = "";
        };

        direnv = {
          disabled = true;
        };

        docker_context = {
          format = "[\\[$symbol$context\\]]($style) ";
          only_with_files = true;
          detect_files = [
            "docker-compose.yml"
            "docker-compose.yaml"
            "Dockerfile"
          ];
          detect_folders = [ "docker-build-env" ];
          style = "blue bold";
          disabled = false;
        };

        git_branch = {
          format = "[\\[$symbol$branch\\]]($style) ";
        };

        helm = {
          format = "[\\[$symbol($version)\\]]($style) ";
          version_format = "v$raw";
          detect_files = [
            "helmfile.yaml"
            "helmfile.yml"
            "Chart.yaml"
            "Chart.yml"
            "values.yaml"
            "values.yml"
          ];
          detect_folders = [ "charts" ];
          disabled = false;
        };

        hostname = {
          ssh_only = true;
        };

        kubernetes = {
          disabled = false;
          symbol = "󱃾 ";
          format = "[\\[$symbol$context\\]]($style) ";
        };

        nix_shell = {
          symbol = " ";
          format = "[\\[$symbol(\($name\))\\]]($style) ";
          heuristic = false;
          disabled = false;
        };

        fill = {
          symbol = "-";
        };
      };
    };
  };
}

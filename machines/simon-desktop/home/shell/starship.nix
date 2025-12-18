{ config, lib, ... }:
{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;
    enableFishIntegration = false; # using tide instead

    settings = {
      format = lib.concatStrings [
        "$all"
        "$fill"
        "$cmd_duration"
        "$kubernetes"
        "$terraform"
        "$package"
        "$nix_shell"
        "$line_break"
        "$status"
        "$jobs"
        "$character"
      ];
      right_format = lib.concatStrings [

      ];
      add_newline = true;

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };

      directory = {
        style = "bold green";
      };

      docker_context = {
        format = "[$symbol$context]($style) ";
        only_with_files = true;
        detect_files = [
          "docker-compose.yml"
          "docker-compose.yaml"
          "Dockerfile"
        ];
      };

      # jj and git integration
      custom = {
        jj = {
          description = "jujutsu vcs status";
          when = "jj --ignore-working-copy root";
          symbol = "󰘬 ";
          command = "jj log -r@ --no-graph --ignore-working-copy --color=never -T 'if(empty, \"·\", \"●\")'";
          format = "[\\[$symbol$output\\]]($style) ";
          style = "bold purple";
        };

        git_branch = {
          when = "! jj --ignore-working-copy root";
          command = "starship module git_branch";
          format = "$output";
          style = "";
          description = "only show git_branch if we're not in a jj repo";
        };

        git_status = {
          when = "! jj --ignore-working-copy root";
          command = "starship module git_status";
          format = "$output";
          style = "";
          description = "only show git_status if we're not in a jj repo";
        };
      };

      # disable original git modules and use custom module with jj support
      git_branch.disabled = true;
      git_status.disabled = true;
      git_commit.disabled = true;

      helm = {
        format = "[$symbol($version)]($style) ";
        detect_files = [
          "helmfile.yaml"
          "helmfile.yml"
          "Chart.yaml"
          "Chart.yml"
          "values.yaml"
          "values.yml"
        ];
      };

      kubernetes = {
        disabled = false;
        symbol = "󱃾 ";
        format = "[$symbol$context]($style) ";
      };

      nix_shell = {
        symbol = " ";
        format = "[$symbol(\($name\))]($style) ";
      };

      fill = {
        symbol = " ";
      };
    };
  };
}

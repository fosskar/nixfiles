{ lib, pkgs, ... }:
let
  ohMyOpencodeConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json";
    google_auth = true;
    experimental = {
      preemptive_compaction = true;
      preemptive_compaction_threshold = 0.98;
    };
  };
in
{
  programs.opencode = {
    enable = true;
    settings = {
      theme = "system";
      autoshare = false;
      autoupdate = false;
      plugin = [ "oh-my-opencode" ];
      provider.anthropic.options.setCacheKey = true;

      formatter = {
        nixfmt = {
          command = [
            (lib.getExe pkgs.nixfmt)
            "$FILE"
          ];
          extensions = [ ".nix" ];
        };
      };

      lsp = {
        nixd = {
          command = [ (lib.getExe pkgs.nixd) ];
          extensions = [ ".nix" ];
          initialization = {
            formatting = {
              command = [ (lib.getExe pkgs.nixfmt) ];
            };
            options = {
              nixos = {
                expr = "(builtins.getFlake \"/home/simon/code/nixfiles\").nixosConfigurations.nixfiles.options";
              };
              home-manager = {
                expr = "(builtins.getFlake \"/home/simon/code/nixfiles\").homeConfigurations.simon.options";
              };
            };
          };
        };
        yamlls = {
          command = [
            (lib.getExe pkgs.yaml-language-server)
            "--stdio"
          ];
          extensions = [
            ".yaml"
            ".yml"
          ];
        };
      };

      mcp = {
        nixos = {
          type = "local";
          command = [
            "nix"
            "run"
            "github:utensils/mcp-nixos"
            "--"
          ];
          enabled = true;
        };
      };
    };
  };

  xdg.configFile = {
    "opencode/oh-my-opencode.json".text = builtins.toJSON ohMyOpencodeConfig;
    "opencode/AGENTS.md".source = ../AGENTS.md;
  };
}

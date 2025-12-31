_:
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

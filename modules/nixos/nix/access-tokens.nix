{
  flake.modules.nixos.nixAccessTokens =
    { config, ... }:
    {
      clan.core.vars.generators.nix-access-tokens = {
        share = true;
        files.tokens.secret = true;
        prompts.tokens = {
          description = "nix access-tokens line (e.g. access-tokens = github.com=ghp_...)";
          type = "multiline";
          persist = true;
        };
        script = "cat $prompts/tokens > $out/tokens";
      };

      nix.extraOptions = ''
        !include ${config.clan.core.vars.generators.nix-access-tokens.files.tokens.path}
      '';
    };
}

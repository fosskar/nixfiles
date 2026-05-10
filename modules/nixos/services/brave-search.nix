{
  flake.modules.nixos.braveSearch =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "bx" ''
          if [ -z "''${BRAVE_SEARCH_API_KEY:-}" ] && [ -r /run/secrets/vars/brave-search/api-key ]; then
            BRAVE_SEARCH_API_KEY="$(cat /run/secrets/vars/brave-search/api-key)"
            export BRAVE_SEARCH_API_KEY
          fi

          exec ${lib.getExe' pkgs.brave-search-cli "bx"} "$@"
        '')
      ];

      clan.core.vars.generators.brave-search = {
        share = true;
        prompts.api-key = {
          description = "Brave Search API key";
          type = "hidden";
          persist = true;
        };
        files.api-key.secret = true;
        files.env.secret = true;
        script = ''
          cp "$prompts/api-key" "$out/api-key"
          echo "BRAVE_SEARCH_API_KEY=$(cat "$prompts/api-key")" > "$out/env"
        '';
      };
    };
}

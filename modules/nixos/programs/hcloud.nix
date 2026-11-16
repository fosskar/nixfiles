{
  flake.modules.nixos.hcloud =
    { config, pkgs, ... }:
    let
      token = config.clan.core.vars.generators.hcloud.files.token;
    in
    {
      clan.core.vars.generators.hcloud = {
        share = true;
        prompts.token = {
          description = "hetzner api token (console > security > api tokens, read & write)";
          type = "hidden";
          persist = true;
        };
        files.token = {
          secret = true;
          owner = "simon";
        };
        script = ''
          cp "$prompts/token" "$out/token"
        '';
      };

      environment.systemPackages = [
        (pkgs.symlinkJoin {
          name = "hcloud-with-token";
          paths = [ pkgs.hcloud ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          # hcloud prefers HCLOUD_TOKEN over ~/.config/hcloud/cli.toml contexts
          postBuild = ''
            wrapProgram $out/bin/hcloud --run 'export HCLOUD_TOKEN="$(cat ${token.path})"'
          '';
        })
      ];
    };
}

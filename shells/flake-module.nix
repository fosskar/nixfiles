_: {
  perSystem =
    {
      config,
      inputs', # flake-parts provides this (perSystem)
      pkgs,
      ...
    }:
    let
      mkScript = name: text: pkgs.writeShellScriptBin name text;

      # patch clan-cli to support SOPS_AGE_KEY_CMD
      # https://git.clan.lol/clan/clan-core/issues/6799
      clan-cli-patched = inputs'.clan-core.packages.clan-cli.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./clan-cli-sops-age-key-cmd.patch ];
      });

      # until it not only a cli flag https://git.clan.lol/clan/clan-core/issues/4624
      scripts = [
        (mkScript "clan" ''
          if [ "$1" = "machines" ] && [ "$2" = "update" ]; then
            ${clan-cli-patched}/bin/clan machines update --build-host localhost "''${@:3}"
          else
            ${clan-cli-patched}/bin/clan "$@"
          fi
        '')
      ];
    in
    {
      devShells = {
        default = pkgs.mkShellNoCC {
          name = "nixfiles";
          shellHook = ''
            ${config.pre-commit.installationScript}
          '';
          packages = [ pkgs.hcloud ] ++ scripts;
        };

        terraform = pkgs.mkShellNoCC {
          name = "nixinfra-terraform";
          packages = [
            (pkgs.opentofu.withPlugins (p: [
              p.hashicorp_external
              p.telmate_proxmox
              p.hetznercloud_hcloud
              p.hashicorp_local
            ]))
          ];
        };
      };
    };
}

{ config, ... }:
{
  perSystem =
    {
      inputs', # flake-parts provides this (perSystem)
      pkgs,
      ...
    }:
    let
      # sops-age-key-cmd: support SOPS_AGE_KEY_CMD, https://git.clan.lol/clan/clan-core/issues/6799
      # select-cache-lock: fix racy select cache in parallel `clan machines update`, https://git.clan.lol/clan/clan-core/pulls/8103
      clan-cli-patched = inputs'.clan-core.packages.clan-cli.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./_clan-cli-sops-age-key-cmd.patch
          ./_clan-cli-select-cache-lock.patch
        ];
      });

      # until it not only a cli flag https://git.clan.lol/clan/clan-core/issues/4624
      defaultShellName = "nixfiles";
      scripts = [
        (pkgs.writeShellScriptBin "clan" ''
          ${clan-cli-patched}/bin/clan "$@"
        '')
      ];
    in
    {
      devShells = {
        default = pkgs.mkShellNoCC {
          name = defaultShellName;
          NIXBOT_URL = "https://nixbot.${config.flake.domains.public}";
          shellHook = ''
            export name="${defaultShellName}"
          '';
          packages = [
            inputs'.nixbot.packages.nixbot-cli
            pkgs.hcloud
            pkgs.nix-fast-build
          ]
          ++ scripts;
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

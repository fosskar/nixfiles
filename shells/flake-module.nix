{ ... }:
{
  perSystem =
    {
      config,
      inputs', # flake-parts provides this (perSystem)
      pkgs,
      ...
    }:
    #let
    #  mkScript = name: text: pkgs.writeShellScriptBin name text;
    #
    #  # until it not only a cli flag https://git.clan.lol/clan/clan-core/issues/4624
    #  scripts = [
    #    (mkScript "clan" ''
    #      if [ "$1" = "machines" ]; then
    #        ${inputs'.clan-core.packages.clan-cli}/bin/clan machines "$2" --build-host localhost "''${@:3}"
    #      else
    #        ${inputs'.clan-core.packages.clan-cli}/bin/clan "$@"
    #      fi
    #    '')
    #  ];
    #in
    {
      devShells = {
        default = pkgs.mkShellNoCC {
          name = "nixinfra";
          shellHook = ''
            ${config.pre-commit.installationScript}
          '';
          packages = [
            config.agenix-rekey.package
            inputs'.clan-core.packages.clan-cli
          ];
          #++ scripts;
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

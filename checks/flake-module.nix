{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      lib,
      pkgs,
      self',
      system,
      ...
    }:
    {
      treefmt = {
        # don't expose as flake check; buildbot-nix would gate PR merge on it.
        # run via `nix fmt` / pre-commit instead.
        flakeCheck = false;
        projectRootFile = "flake.nix";
        settings.global.excludes = [
          "*.gitignore"
          "*.pub"
          "*.priv"
          "*.age"
          "*.svg"
          "*.patch"
          ".envrc"
          "**/.envrc"
          "LICENSE"
          "**/LICENSE"
          "flake.lock"
          "**/flake.lock"
          "result"
          "**/result"
          "sops/secrets/*"
          "**/sops/secrets/*"
          "vars/*"
          "**/vars/*"
        ];
        settings.formatter.flake-edit = {
          command = pkgs.flake-edit;
          options = [
            "--non-interactive"
            "--no-lock"
            "follow"
          ];
          includes = [ "flake.nix" ];
        };
        programs = {
          nixfmt.enable = true;
          prettier.enable = true;
          deadnix.enable = true;
          statix.enable = true;
          shfmt.enable = true;
          shellcheck.enable = true;
          yamlfmt.enable = true;
        };
      };

      checks =
        let
          machinesPerSystem = {
            x86_64-linux = [
              "crowbox"
              "gateway"
              "lpt-titan"
              "nixbox"
              "nixworker"
              "simon-desktop"
            ];
          };

          listedMachines = lib.sort lib.lessThan (lib.concatLists (lib.attrValues machinesPerSystem));
          actualMachines = lib.sort lib.lessThan (lib.attrNames inputs.self.nixosConfigurations);
          machinesPerSystemCheck = pkgs.runCommand "machines-per-system-check" { } ''
            ${lib.optionalString (listedMachines != actualMachines) ''
              echo "machinesPerSystem out of sync with nixosConfigurations:"
              echo "  listed: ${lib.concatStringsSep " " listedMachines}"
              echo "  actual: ${lib.concatStringsSep " " actualMachines}"
              exit 1
            ''}
            touch $out
          '';

          nixosMachines = lib.mapAttrs' (name: lib.nameValuePair "nixos-${name}") (
            lib.genAttrs (machinesPerSystem.${system} or [ ]) (
              name: inputs.self.nixosConfigurations.${name}.config.system.build.toplevel
            )
          );

          packages = lib.mapAttrs' (name: pkg: lib.nameValuePair "package-${name}" pkg) (
            self'.packages or { }
          );

          devShells = lib.mapAttrs' (name: shell: lib.nameValuePair "devshell-${name}" shell) (
            self'.devShells or { }
          );

          homeConfigurations = lib.mapAttrs' (
            name: home: lib.nameValuePair "home-${name}" home.activation-script
          ) ((self'.legacyPackages or { }).homeConfigurations or { });
        in
        {
          inherit machinesPerSystemCheck;
        }
        // nixosMachines
        // packages
        // devShells
        // homeConfigurations;
    };
}

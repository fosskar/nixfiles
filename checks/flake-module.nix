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
        # don't expose as flake check; nixbot would gate PR merge on it.
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
          "**/facter.json"
          "result"
          "**/result"
          "sops/secrets/*"
          "**/sops/secrets/*"
          "vars/*"
          "**/vars/*"
        ];
        settings.formatter.nixf-diagnose = {
          command = pkgs.nixf-diagnose;
          includes = [ "*.nix" ];
        };
        settings.formatter.flake-edit = {
          command = pkgs.flake-edit;
          options = [
            "--non-interactive"
            "--no-lock"
            "--config"
            "${pkgs.writeText "flake-edit.toml" ''
              [follow]
              ignore = ["zed.nixpkgs"]
            ''}"
            "follow"
          ];
          includes = [ "flake.nix" ];
        };
        programs = {
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rs;
          };
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
          # machines deliberately excluded from CI builds
          excludedMachines = [ ];

          nixosMachines =
            lib.mapAttrs' (name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel)
              (
                lib.filterAttrs (
                  name: cfg: !(lib.elem name excludedMachines) && cfg.pkgs.stdenv.hostPlatform.system == system
                ) inputs.self.nixosConfigurations
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
        nixosMachines // packages // devShells // homeConfigurations;
    };
}

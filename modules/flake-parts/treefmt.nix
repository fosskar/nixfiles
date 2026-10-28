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
        imports = [ inputs.ai-tells-lint.treefmtModules.default ];
        # don't expose as flake check; nixbot would gate PR merge on it.
        # run via `nix fmt` instead.
        flakeCheck = false;
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
          # sops-encrypted; let sops own the layout
          "secrets.yaml"
          "**/secrets.yaml"
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
              ignore = ["zed.nixpkgs", "llm-agents.nixpkgs", "llm-agents.bun2nix.nixpkgs"]
            ''}"
            "follow"
          ];
          includes = [ "flake.nix" ];
        };
        programs = {
          ai-tells-lint = {
            enable = true;
            excludes = [
              "templates/*"
              # verbatim upstream skill stubs
              "modules/llm/orca/skills/*"
            ];
          };
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rs;
          };
          prettier.enable = true;
          deadnix.enable = true;
          statix.enable = true;
          shfmt.enable = true;
          shellcheck.enable = true;
          taplo.enable = true;
          gofmt.enable = true;
          rustfmt.enable = true;
          ruff-check = {
            enable = true;
            extendSelect = [ "I" ];
          };
          ruff-format.enable = true;
        };
        settings.formatter.ruff-check.options = [ "--no-cache" ];
        settings.formatter.ruff-format.options = [ "--no-cache" ];
      };

      checks =
        let
          nixosMachines =
            lib.mapAttrs' (name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel)
              (
                lib.filterAttrs (
                  _: cfg: cfg.pkgs.stdenv.hostPlatform.system == system
                ) inputs.self.nixosConfigurations
              );

          # hydraPlatforms = [ ] opts a package out, e.g. when its source is not downloadable
          availablePackages = lib.filterAttrs (
            _: pkg:
            lib.meta.availableOn pkgs.stdenv.hostPlatform pkg && (pkg.meta.hydraPlatforms or null) != [ ]
          ) (self'.packages or { });

          packages = lib.mapAttrs' (name: pkg: lib.nameValuePair "package-${name}" pkg) availablePackages;

          packageTests = lib.concatMapAttrs (
            name: pkg:
            lib.mapAttrs' (test: drv: lib.nameValuePair "package-${name}-test-${test}" drv) (
              pkg.passthru.tests or { }
            )
          ) availablePackages;

          devShells = lib.mapAttrs' (name: shell: lib.nameValuePair "devshell-${name}" shell) (
            self'.devShells or { }
          );
        in
        nixosMachines // packages // packageTests // devShells;
    };
}

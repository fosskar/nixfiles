{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      config,
      lib,
      pkgs,
      self',
      system,
      ...
    }:
    {
      # `nix fmt` uses the treefmt wrapper configured below
      formatter = config.treefmt.build.wrapper;

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

          # local packages that only build on x86_64; skip them in CI on other
          # systems (pkgs-by-name exposes them everywhere, but they're x86-only)
          x86OnlyPackages = [
            "agent-desktop"
            "arbor"
            "brave-origin"
            "kittylitter"
            "limux"
            "t3code"
            "voquill"
          ];
          packages = lib.mapAttrs' (name: pkg: lib.nameValuePair "package-${name}" pkg) (
            lib.filterAttrs (name: _: system == "x86_64-linux" || !(lib.elem name x86OnlyPackages)) (
              self'.packages or { }
            )
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

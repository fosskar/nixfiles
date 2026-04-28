{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      lib,
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
          nixosMachines =
            lib.mapAttrs'
              (name: machine: lib.nameValuePair "nixos-${name}" machine.config.system.build.toplevel)
              (
                lib.filterAttrs (
                  _: machine: machine.pkgs.stdenv.hostPlatform.system == system
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

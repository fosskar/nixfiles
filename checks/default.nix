{ inputs, ... }:
{
  imports = [
    inputs.git-hooks.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {
    treefmt = {
      projectRootFile = "flake.nix";
      settings.global.excludes = [
        "*.gitignore"
        "*.pub"
        "*.priv"
        "*.age"
        "*/sops/secrets/*"
        "vars/*"
        "*.md"
      ];
      programs = {
        nixfmt.enable = true;
        prettier.enable = true;
        deadnix.enable = true;
        shellcheck.enable = true;
      };
    };

    pre-commit = {
      settings = {
        excludes = [
          "flake.lock"
          "CHANGELOG.md"
          "LICENSE"
        ];
        hooks = {
          treefmt.enable = true;
          flake-checker.enable = true;
          nil.enable = true;
          detect-private-keys.enable = true;
        };
      };
    };
  };
}

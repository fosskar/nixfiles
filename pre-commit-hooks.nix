{ inputs, ... }:
{
  imports = [ inputs.pre-commit-hooks.flakeModule ];

  perSystem.pre-commit = {
    check.enable = true;
    settings = {
      excludes = [
        "flake.lock"
        "CHANGELOG.md"
        "LICENSE"
      ];
      src = ./.;
      hooks = {
        nixfmt = {
          enable = true;
        };

        ## statix and deadnix should be covered by nixfmt
        #statix = {
        #  enable = true;
        #  fail_fast = true;
        #};

        #deadnix = {
        #  enable = true;
        #  fail_fast = true;
        #  settings = {
        #    edit = true;
        #  };
        #};

        #yamllint = {
        #  enable = true;
        #  fail_fast = true;
        #  settings = {
        #    format = "colored";
        #    preset = "relaxed";
        #    configuration = ''
        #      ---
        #      extends: relaxed
        #      rules:
        #        braces:
        #          level: warning
        #          max-spaces-inside: 1
        #        brackets:
        #          level: warning
        #          max-spaces-inside: 1
        #        colons:
        #          level: warning
        #        commas:
        #          level: warning
        #        comments: disable
        #        comments-indentation: disable
        #        document-start: disable
        #        empty-lines:
        #          level: warning
        #        hyphens:
        #          level: warning
        #        indentation:
        #          level: warning
        #          indent-sequences: consistent
        #        line-length: disable
        #        truthy: disable
        #    '';
        #  };
        #};

        prettier = {
          enable = true;
          fail_fast = true;
          excludes = [
            ".md"
            ".nix"
            ".yaml"
            ".yml"
          ];
          settings = {
            write = true;
          };
        };

        pre-commit-hook-ensure-sops.enable = true;
      };
    };
  };
}

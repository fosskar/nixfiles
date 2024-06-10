{inputs, ...}: {
  imports = [inputs.pre-commit-hooks.flakeModule];

  perSystem.pre-commit.settings = {
    excludes = [
      "flake.lock"
      "CHANGELOG.md"
      "LICENSE"
    ];
    hooks = {
      alejandra = {
        enable = true;
        fail_fast = true;
        settings = {
          check = false;
        };
      };

      statix = {
        enable = true;
        fail_fast = true;
      };

      deadnix = {
        enable = true;
        fail_fast = true;
        settings = {
          edit = true;
        };
      };

      yamllint = {
        enable = true;
        fail_fast = true;
        settings = {
          format = "colored";
          preset = "relaxed";
          configuration = ''
            ---

            extends: relaxed

            rules:
              braces:
                level: warning
                max-spaces-inside: 1
              brackets:
                level: warning
                max-spaces-inside: 1
              colons:
                level: warning
              commas:
                level: warning
              comments: disable
              comments-indentation: disable
              document-start: disable
              empty-lines:
                level: warning
              hyphens:
                level: warning
              indentation:
                level: warning
                indent-sequences: consistent
              line-length: disable
              truthy: disable
          '';
        };
      };

      #typos = {
      #  enable = true;
      #  settings = {
      #    write = true;
      #    configPath = "./.typos.toml";
      #  };
      #};

      #prettier = {
      #  enable = true;
      #  fail_fast = true;
      #  excludes = [".js" ".md" ".ts" ".scss" ".css"];
      #  settings = {
      #    write = true;
      #  };
      #};

      shellcheck = {
        enable = true;
        excludes = ["png"];
        types_or = ["shell"];
      };

      pre-commit-hook-ensure-sops.enable = true;
    };
  };
}

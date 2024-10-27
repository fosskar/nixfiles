{
  self,
  inputs,
  system,
  ...
}:

inputs.pre-commit-hooks.lib.${system}.run {
  src = self;
  excludes = [
    "flake.lock"
    "CHANGELOG.md"
    "LICENSE"
  ];
  hooks =
    let
      fail_fast = true;
      verbose = true;
    in
    {
      nixfmt-rfc-style = {
        enable = true;
        inherit fail_fast verbose;
      };

      flake-checker = {
        enable = true;
        inherit fail_fast verbose;
      };

      nil = {
        enable = true;
        inherit fail_fast verbose;
      };

      prettier = {
        enable = true;
        settings = {
          write = true;
        };
        inherit fail_fast verbose;
      };

      deadnix = {
        enable = true;
        inherit fail_fast verbose;
      };

      statix = {
        enable = true;
        inherit fail_fast verbose;
      };

      markdownlint = {
        enable = false;
        settings.configuration = {
          MD013 = {
            line_length = 0;
          };
          inherit fail_fast verbose;
        };
      };

      detect-private-keys = {
        enable = true;
        inherit fail_fast;
      };
    };
}

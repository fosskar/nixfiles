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
    in
    #verbose = true;
    {
      nixfmt-rfc-style = {
        enable = true;
        inherit fail_fast;
      };

      flake-checker = {
        enable = true;
        inherit fail_fast;
      };

      nil = {
        enable = true;
        inherit fail_fast;
      };

      prettier = {
        enable = true;
        settings = {
          write = true;
        };
        inherit fail_fast;
      };

      deadnix = {
        enable = true;
        inherit fail_fast;
      };

      statix = {
        enable = true;
        inherit fail_fast;
      };

      markdownlint = {
        enable = false;
        settings.configuration = {
          MD013 = {
            line_length = 0;
          };
          inherit fail_fast;
        };
      };

      detect-private-keys = {
        enable = true;
        inherit fail_fast;
      };
    };
}

{
  self,
  inputs,
  system,
  ...
}:

inputs.pre-commit-hooks.lib.${system}.run {
  src = self;
  excludes = [
    "${self}/flake.lock"
    "${self}/CHANGELOG.md"
    "${self}/LICENSE"
  ];
  hooks = {
    nixfmt-rfc-style = {
      enable = true;
    };

    prettier = {
      enable = true;
      fail_fast = true;
      settings = {
        write = true;
      };
    };

    deadnix = {
      enable = true;
      fail_fast = true;
    };

    statix = {
      enable = true;
    };

    pre-commit-hook-ensure-sops = {
      enable = true;
    };
  };
}

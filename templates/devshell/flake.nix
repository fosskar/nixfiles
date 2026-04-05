{
  description = "DevShell for project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;

          config = {
            allowUnfree = true;
          }
          // nixpkgs.lib.optionalAttrs (system == "x86_64-darwin") {
            allowDeprecatedx86_64Darwin = true;
          };
        };
      in
      {
        devShell =
          with pkgs;
          mkShell {
            buildInputs = [ ];
          };
      }
    );
}

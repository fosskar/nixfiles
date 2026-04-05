{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  outputs =
    {
      self,
      nixpkgs,
      poetry2nix,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config = nixpkgs.lib.optionalAttrs (system == "x86_64-darwin") {
            allowDeprecatedx86_64Darwin = true;
          };
        }
      );
    in
    {
      packages = forAllSystems (
        system:
        let
          inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs.${system}; }) mkPoetryApplication;
        in
        {
          default = mkPoetryApplication { projectDir = self; };
        }
      );

      devShells = forAllSystems (
        system:
        let
          inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs.${system}; }) mkPoetryEnv;
        in
        {
          default = pkgs.${system}.mkShellNoCC {
            packages = with pkgs.${system}; [
              (mkPoetryEnv { projectDir = self; })
              poetry
              (python3.withPackages (
                ps: with ps; [
                  flake8
                  ipython
                  mypy
                  pip
                  pytest
                ]
              ))
              black
              ruff
            ];
          };
        }
      );
    };
}

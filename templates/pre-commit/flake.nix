{
  description = "pre-commit-hook-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              ## nix
              #alejandra.enable = true;
              #deadnix.enable = true;
              #flake-checker.enable = true;
              #nil.enable = true;
              #nixfmt-rfc-style.enable = true;
              #statix.enable = false;

              ## haskell
              #cabal-fmt.enable = true;
              #fourmolu.enable = true;
              #hindent.enable = true;
              #hlint.enable = true;
              #hpack.enable = true;
              #ormolu.enable = true;
              #stylish-haskell.enable = true;

              ## c
              #clang-format.enable = true;
              #clang-tidy.enable = true;

              ## clojure
              #cljfmt.enable = true;
              #zprint.enable = true;

              ## elm
              #elm-format.enable = true;
              #elm-review.enable = true;
              #elm-test.enable = true;

              ## elixir
              #credo.enable = true;
              #dialyzer.enable = true;
              #mix-format.enable = true;
              #mix-test.enable = true;

              ## ocaml
              #dune-fmt.enable = true;
              #dune-opam-sync.enable = true;
              #ocp-indent.enable = true;
              #opam-lint.enable = true;

              ## purescript
              #purty.enable = true;

              ## javascript / typescript
              #biome.enable = true;
              #eslint.enable = true;

              ## python
              #autoflake.enable = true;
              #black.enable = true;
              #check-builtin-literals.enable = true;
              #check-docstring-first.enable = true;
              #check-python.enable = true;
              #fix-encoding-pragma.enable = true;
              #flake8.enable = true;
              #isort.enable = true;
              #mypy.enable = true;
              #name-tests-test.enable = true;
              #pylint.enable = true;
              #pyright.enable = true;
              #python-debug-statements.enable = true;
              #poetry.enable = true;
              #pyupgrade.enable = true;
              #ruff.enable = true;
              #ruff-format.enable = true;
              #sort-requirements-txt.enable = true;

              ## php
              #phpcbf
              #php-cs-fixer
              #phpcs
              #phpstan
              #psalm

              ## rust
              #cargo-check.enable = true;
              #clippy.enable = true;
              #rustfmt.enable = true;

              ## golang
              #gofmt.enable = true;
              #golangci-lint.enable = true;
              #gotest.enable = true;
              #govet.enable = true;
              #revive.enable = true;
              #staticcheck.enable = true;

              ## julia
              #JuiaFormatter.jl.enable = true;

              ## shell
              #bats.enable = true;
              #beautysh.enable = true;
              #shellcheck.enable = true;
              #shfmt.enable = true;

              ## laTeX
              #chktex.enable = true;
              #lacheck.enable = true;
              #latexindent.enable = true;

              ## lua
              #luacheck.enable = true;
              #lua-ls.enable = true;
              #stylua.enable = true;

              ## html
              #html-tidy.enable = true;

              ## markdown
              #markdownlint.enable = true;
              #mdl.enable = true;
              #mdsh.enable = true;

              ## terraform
              #terraform-format.enable = true;
              #terraform-validate.enable = true;
              #tflint.enable = true;

              ## yaml
              #check-yaml.enable = true;
              #sort-simple-yaml.enable = true;
              #yamlfmt.enable = true;
              #yamllint.enable = true;

              ## toml
              #check-toml.enable = true;
              #taplo-fmt.enable = true;

              ## json
              #check-json.enable = true;
              #pretty-format-json.enable = true;

              ## typst
              #typstfmt.enable = true;
              #typstyle.enable = true;

              ## fortran
              #fprettify.enable = true;

              ## spell checker
              #cspell.enable = true;
              #hunspell.enable = true;
              #typos.enable = true;

              ## link checker
              #lychee.enable = true;
              #mkdocs-linkcheck.enable = true;

              ## git
              #annex.enable = true;
              #check-merge-conflicts.enable = true;
              #commitizen.enable = true;
              #convco.enable = true;
              #forbid-new-submodules.enable = true;
              #gptcommit.enable = true;
              #no-commit-to-branch.enable = true;

              ## various
              #actionlint.enable = true;
              #check-added-large-files.enable = true;
              #check-case-conflicts.enable = true;
              #check-executables-have-shebangs.enable = true;
              #checkmake.enable = true;
              #check-shebang-scripts-are-executable.enable = true;
              #check-symlinks.enable = true;
              #check-vcs-permalinks.enable = true;
              #check-xml.enable = true;
              #cmake-format.enable = true;
              #crystal.enable = true;
              #detect-aws-credentials.enable = true;
              #detect-private-keys.enable = true;
              #dhall-format.enable = true;
              #editorconfig-checker.enable = true;
              #end-of-file-fixer.enable = true;
              #fix-byte-order-marker.enable = true;
              #hadolint.enable = true;
              #headache.enable = true;
              #mixed-line-endings.enable = true;
              #mkdocs-linkcheck.enable = true;
              #prettier.enable = true;
              #sort-file-contents.enable = true;
              #tagref.enable = true;
              #topiary.enable = true;
              #treefmt.enable = true;
              #trim-trailing-whitespace.enable = true;
            };
          };
        };
        devShells.default = pkgs.mkShell { inherit (self.checks.${system}.pre-commit-check) shellHook; };
      }
    );
}

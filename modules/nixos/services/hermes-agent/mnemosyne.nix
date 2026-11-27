_: {
  # local memory provider: sqlite with vector and fts5 recall. the catalog
  # plugin is a thin loader; the implementation lives in two pypi packages
  # that hermes would pip-install at runtime, so they are built here instead.
  # the embedding model downloads into HERMES_HOME/cache/fastembed on first use
  flake.modules.nixos.hermesMnemosyne =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      python = config.services.hermes-agent.package.python.pkgs;

      # hermes' build refuses any extra package its sealed venv already has
      # (numpy, onnxruntime, requests, ...), so the closure keeps only these
      # and imports the rest from that venv
      missingFromHermes = [
        "coloredlogs"
        "fastembed"
        "humanfriendly"
        "loguru"
        "mmh3"
        "mnemosyne-memory"
        "py-rust-stemmers"
        "pystemmer"
        "sqlite-vec"
      ];
      keep = dep: lib.elem (lib.toLower (dep.pname or "")) missingFromHermes;
      onlyMissing =
        package:
        if !(package ? overridePythonAttrs) then
          package
        else
          package.overridePythonAttrs (old: {
            dependencies = map onlyMissing (lib.filter keep (old.dependencies or [ ]));
            propagatedBuildInputs = map onlyMissing (lib.filter keep (old.propagatedBuildInputs or [ ]));
            # the dropped dependencies resolve only inside the hermes venv
            dontCheckRuntimeDeps = true;
            pythonImportsCheck = [ ];
            doCheck = false;
          });

      wheel =
        {
          pname,
          version,
          url,
          hash,
          dependencies,
        }:
        onlyMissing (
          python.buildPythonPackage {
            inherit pname version dependencies;
            format = "wheel";
            src = pkgs.fetchurl { inherit url hash; };
          }
        );

      mnemosyne-memory = wheel {
        pname = "mnemosyne-memory";
        version = "4.0.0";
        url = "https://files.pythonhosted.org/packages/af/d3/ebab3bdf259c8d6f1b572552356751e5f224e2bce4494040611708c3657d/mnemosyne_memory-4.0.0-py3-none-any.whl";
        hash = "sha256-PoC/9jkhq1VNPbwXFpAOBkwxdEt+YBNdmXX3OnMCanY=";
        # the [embeddings] extra; pyyaml and onnxruntime come from the hermes venv
        dependencies = [
          python.fastembed
          python.sqlite-vec
        ];
      };

      mnemosyne-hermes = wheel {
        pname = "mnemosyne-hermes";
        version = "0.7.7";
        url = "https://files.pythonhosted.org/packages/49/1f/0ee073e29e47c2e67293aba12f617d3f478654c1f6a10ab3b3cbaeabc6c4/mnemosyne_hermes-0.7.7-py3-none-any.whl";
        hash = "sha256-SXSZb9MoqPp3Uay8yt9xKDfU6dcDr88HBnkWzjNqPQ8=";
        dependencies = [ mnemosyne-memory ];
      };
    in
    {
      services.hermes-agent = {
        catalogPlugins = [ "mnemosyne" ];
        extraPythonPackages = [ mnemosyne-hermes ];
        overrides.memory.provider = "mnemosyne";
      };
    };
}

{ rootPath, ... }:
{
  flake.templates = {
    clanService = {
      description = "Clan service template";
      path = rootPath + "/templates/clanService";
    };

    devshell = {
      description = "Flake devshell template";
      path = rootPath + "/templates/devshell";
    };

    go = {
      description = "Flake GO template";
      path = rootPath + "/templates/go";
    };

    module = {
      description = "NixOS module template";
      path = rootPath + "/templates/module";
    };

    overlay = {
      description = "NixOS overlay template";
      path = rootPath + "/templates/overlay";
    };

    node = {
      description = "Flake node template";
      path = rootPath + "/templates/node";
    };

    python = {
      description = "Flake Python template";
      path = rootPath + "/templates/python";
    };

    rust = {
      description = "Flake Rust template";
      path = rootPath + "/templates/rust";
    };
  };
}

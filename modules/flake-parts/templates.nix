{ self, ... }:
{
  flake.templates = {
    clanService = {
      description = "Clan service template";
      path = self.outPath + "/templates/clanService";
    };

    devshell = {
      description = "Flake devshell template";
      path = self.outPath + "/templates/devshell";
    };

    go = {
      description = "Flake GO template";
      path = self.outPath + "/templates/go";
    };

    module = {
      description = "NixOS module template";
      path = self.outPath + "/templates/module";
    };

    overlay = {
      description = "NixOS overlay template";
      path = self.outPath + "/templates/overlay";
    };

    node = {
      description = "Flake node template";
      path = self.outPath + "/templates/node";
    };

    python = {
      description = "Flake Python template";
      path = self.outPath + "/templates/python";
    };

    rust = {
      description = "Flake Rust template";
      path = self.outPath + "/templates/rust";
    };
  };
}

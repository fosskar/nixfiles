_: {
  flake.templates = {
    devshell = {
      description = "Flake devshell template";
      path = ./devshell;
    };

    go = {
      description = "Flake GO template";
      path = ./go;
    };

    module = {
      description = "NixOS module template";
      path = ./module;
    };

    overlay = {
      description = "NixOS overlay template";
      path = ./overlay;
    };

    node = {
      description = "Flake node template";
      path = ./node;
    };

    python = {
      description = "Flake Python template";
      path = ./python;
    };

    rust = {
      description = "Flake Rust template";
      path = ./rust;
    };
  };
}

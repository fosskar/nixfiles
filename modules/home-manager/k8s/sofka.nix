_: {
  flake.modules.homeManager.sofka =
    { inputs, ... }:
    {
      imports = [ inputs.sofka.homeManagerModules.sofka ];

      programs.sofka = {
        enable = true;
        skin.name = "flexoki-dark";
        settings = {
          default_resource = "namespaces";
          experimental.native_describe = true;
        };
      };
    };
}

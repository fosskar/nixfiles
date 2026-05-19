_: {
  _class = "clan.service";

  manifest = {
    name = "template";
    description = "";
    categories = [ "System" ];
    readme = ''
      # usage

      ```nix
      inventory.instances.<name> = {
        module.name = "<input>/<service>";
        module.input = "<input>";

        roles.default.machines."<machine>".settings = { };
      };
      ```
    '';
  };

  roles.default = {
    description = "default service role";

    interface =
      { lib, ... }:
      {
        options.templateOption = lib.mkOption {
          type = lib.types.str;
          default = "template";
          description = "template option";
        };
      };

    perInstance = _: {
      nixosModule = _: {
        # configure NixOS for each machine assigned to this role here.
      };
    };
  };

  perMachine = _: {
    nixosModule = _: {
      # configure NixOS once per machine, after all instances are known, here.
    };
  };
}

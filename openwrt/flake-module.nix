_: {
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      openwrtLib = import ./nix/lib.nix { inherit lib; };

      # evaluate a device config through the module system
      evalDevice =
        configuration:
        (lib.evalModules {
          modules = [
            { _module.args = { inherit pkgs; }; }
            ./nix/module-options.nix
            configuration
          ];
        }).config;

      # auto-discover devices from openwrt/devices/*/config.nix
      deviceDirs = lib.filterAttrs (
        name: type: type == "directory" && builtins.pathExists ./devices/${name}/config.nix
      ) (builtins.readDir ./devices);
      devices = lib.mapAttrs (name: _: evalDevice ./devices/${name}/config.nix) deviceDirs;

      deviceNames = lib.concatStringsSep ", " (builtins.attrNames devices);

      # UCI batch generation (per device)
      mkWriteUci = import ./nix/uci.nix { inherit pkgs lib openwrtLib; };
      uciOutputs = lib.mapAttrs mkWriteUci devices;

      # scripts
      scriptArgs = {
        inherit
          pkgs
          lib
          devices
          deviceNames
          ;
      };
      deployScript = import ./nix/scripts/deploy.nix (scriptArgs // { inherit uciOutputs; });
      fetchScript = import ./nix/scripts/fetch.nix scriptArgs;
      diffScript = import ./nix/scripts/diff.nix (scriptArgs // { inherit uciOutputs; });
    in
    {
      apps = {
        openwrt-deploy = {
          type = "app";
          program = lib.getExe deployScript;
        };
        openwrt-fetch = {
          type = "app";
          program = lib.getExe fetchScript;
        };
        openwrt-diff = {
          type = "app";
          program = lib.getExe diffScript;
        };
      };

      packages = lib.mapAttrs' (
        name: _: lib.nameValuePair "openwrt-uci-${name}" (mkWriteUci name devices.${name}).uciBatch
      ) devices;
    };
}

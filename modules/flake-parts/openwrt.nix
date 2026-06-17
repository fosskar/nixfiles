{ rootPath, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      openwrtLib = import (rootPath + "/openwrt/nix/lib.nix") { inherit lib; };

      # evaluate a device config through the module system
      evalDevice =
        configuration:
        (lib.evalModules {
          modules = [
            { _module.args = { inherit pkgs; }; }
            (rootPath + "/openwrt/nix/module-options.nix")
            configuration
          ];
        }).config;

      # auto-discover devices from openwrt/devices/*/config.nix
      deviceDirs = lib.filterAttrs (
        name: type:
        type == "directory" && builtins.pathExists (rootPath + "/openwrt/devices/${name}/config.nix")
      ) (builtins.readDir (rootPath + "/openwrt/devices"));
      devices = lib.mapAttrs (
        name: _: evalDevice (rootPath + "/openwrt/devices/${name}/config.nix")
      ) deviceDirs;

      deviceNames = lib.concatStringsSep ", " (builtins.attrNames devices);

      # UCI batch generation (per device)
      mkWriteUci = import (rootPath + "/openwrt/nix/uci.nix") { inherit pkgs lib openwrtLib; };
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
      deployScript = import (rootPath + "/openwrt/nix/scripts/deploy.nix") (
        scriptArgs // { inherit uciOutputs; }
      );
      fetchScript = import (rootPath + "/openwrt/nix/scripts/fetch.nix") scriptArgs;
      diffScript = import (rootPath + "/openwrt/nix/scripts/diff.nix") (
        scriptArgs // { inherit uciOutputs; }
      );
    in
    {
      apps = {
        openwrt-deploy = {
          type = "app";
          program = lib.getExe deployScript;
          meta.description = "deploy openwrt device config via uci batch";
        };
        openwrt-fetch = {
          type = "app";
          program = lib.getExe fetchScript;
          meta.description = "fetch live openwrt uci config";
        };
        openwrt-diff = {
          type = "app";
          program = lib.getExe diffScript;
          meta.description = "diff generated vs live openwrt uci config";
        };
      };

      packages = lib.mapAttrs' (
        name: _: lib.nameValuePair "openwrt-uci-${name}" (mkWriteUci name devices.${name}).uciBatch
      ) devices;
    };
}

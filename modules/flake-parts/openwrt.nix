{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      dir = self.outPath + "/openwrt";

      # evaluate a device config through the module system
      evalDevice =
        configuration:
        (lib.evalModules {
          modules = [
            { _module.args = { inherit pkgs; }; }
            (dir + "/nix/module-options.nix")
            configuration
          ];
        }).config;

      # auto-discover devices from openwrt/devices/*/config.nix
      deviceDirs = lib.filterAttrs (
        name: type: type == "directory" && builtins.pathExists (dir + "/devices/${name}/config.nix")
      ) (builtins.readDir (dir + "/devices"));
      devices = lib.mapAttrs (name: _: evalDevice (dir + "/devices/${name}/config.nix")) deviceDirs;

      deviceNames = lib.concatStringsSep ", " (builtins.attrNames devices);

      inherit (import (dir + "/nix/render.nix") { inherit pkgs lib; }) render configJson;
      configJsons = lib.mapAttrs configJson devices;
      ucode = import (dir + "/nix/ucode.nix") { inherit pkgs; };

      # applies each device config to an empty root twice; the second run must plan no changes
      applyCheck =
        name: json:
        pkgs.runCommand "openwrt-apply-${name}"
          {
            nativeBuildInputs = [
              render
              ucode
              pkgs.jq
            ];
          }
          ''
            root=$PWD/root
            mkdir -p "$root/etc/config"
            printf 'root:*:19000:0:99999:7:::\n' > "$root/etc/shadow"
            jq '[.. | strings | scan("@([A-Za-z0-9_]+)@") | .[0]] | map({key: ., value: "dummy-\(.)"}) | from_entries' \
              ${json} > secrets.json
            overrides=$(jq -n --arg root "$root" \
              '{root: $root, no_exec: true, packages: [], remove_packages: [], external_packages: [], disable_services: []}')
            export ROOT_PASSWORD_HASH='$6$salt$hash'
            openwrt-render ${json} secrets.json apply "$overrides" | ucode -
            openwrt-render ${json} secrets.json plan "$overrides" | ucode - | tee plan.txt
            [ "$(cat plan.txt)" = "no changes" ]
            touch $out
          '';

      scriptArgs = {
        inherit
          pkgs
          lib
          devices
          deviceNames
          ;
      };
      deployScript = import (dir + "/nix/scripts/deploy.nix") (
        scriptArgs // { inherit configJsons render; }
      );
      fetchScript = import (dir + "/nix/scripts/fetch.nix") scriptArgs;
      diffScript = import (dir + "/nix/scripts/diff.nix") {
        inherit pkgs lib;
        deploy = deployScript;
      };
    in
    {
      apps = {
        openwrt-deploy = {
          program = lib.getExe deployScript;
          meta.description = "deploy openwrt device config via ucode, with rollback";
        };
        openwrt-fetch = {
          program = lib.getExe fetchScript;
          meta.description = "print openwrt uci changes from factory defaults as nix";
        };
        openwrt-diff = {
          program = lib.getExe diffScript;
          meta.description = "show what an openwrt deploy would change";
        };
      };

      packages = lib.mapAttrs' (name: json: lib.nameValuePair "openwrt-config-${name}" json) configJsons;

      checks = lib.mapAttrs' (
        name: json: lib.nameValuePair "openwrt-apply-${name}" (applyCheck name json)
      ) configJsons;
    };
}

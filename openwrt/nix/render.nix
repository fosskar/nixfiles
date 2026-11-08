# device config -> json for apply.uc, plus the renderer that adds secrets
{ pkgs, lib }:
let
  octal = s: lib.foldl' (acc: d: acc * 8 + lib.toInt d) 0 (lib.stringToCharacters s);

  # usage: openwrt-render <config.json> <secrets.json> plan|apply [overrides-json]
  # prints the ucode program; ROOT_PASSWORD_HASH sets the root password hash
  render = pkgs.writeShellApplication {
    name = "openwrt-render";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      overrides=''${4:-}
      [ -n "$overrides" ] || overrides='{}'
      cfg=$(ROOT_PASSWORD_HASH=''${ROOT_PASSWORD_HASH:-} jq -nc \
        --slurpfile c "$1" --slurpfile s "$2" --arg mode "$3" --argjson overrides "$overrides" \
        -f ${./render.jq})
      printf "'use strict';\nconst cfg = %s;\n" "$cfg"
      cat ${./apply.uc}
    '';
  };

  configJson =
    name: device:
    let
      inherit (device.uci) settings;
    in
    pkgs.writeText "openwrt-${name}.json" (
      builtins.toJSON {
        inherit (device) packages;
        remove_packages = device.removePackages;
        external_packages = map (p: {
          inherit (p) name;
          check = if p.checkCommand != "" then p.checkCommand else "apk info -e ${lib.escapeShellArg p.name}";
          install = p.installCommand;
        }) device.externalPackages;
        disable_services = device.disableServices;
        files = lib.mapAttrsToList (path: f: {
          inherit path;
          inherit (f) content restart;
          mode = octal f.mode;
        }) device.files;
        root_password_secret = device.rootPasswordSecret;
        uci = {
          inherit settings;
          inherit (device.uci) delete;
          exclusive = map (
            c: if settings ? ${c} then c else throw "device ${name}: uci.exclusive ${c} is not in uci.settings"
          ) device.uci.exclusive;
        };
      }
    );
in
{
  inherit render configJson;
}

# generates UCI batch commands with optional sops secret substitution
{
  pkgs,
  lib,
  openwrtLib,
}:
name: device:
let
  uciCommands = openwrtLib.serializeUci device.uci.settings;
  uciBatch = pkgs.writeText "uci-${name}.batch" uciCommands;
  sopsFiles = device.uci.secrets.sops.files;
  hasSops = sopsFiles != [ ];

  checkPlaceholders = ''
    remaining=$(grep -oP '@[^@]+@' <<< "$commands" || true)
    if [ -n "$remaining" ]; then
      echo "error: unsubstituted secret placeholders found:" >&2
      echo "$remaining" | sort -u >&2
      echo "" >&2
      ${
        if hasSops then
          ''echo "secrets file(s) are configured but don't contain these keys" >&2''
        else
          ''echo "no sops files configured — add uci.secrets.sops.files to your device config" >&2''
      }
      exit 1
    fi
  '';

  command = pkgs.writeShellScript "uci-${name}" (
    if hasSops then
      ''
        set -euo pipefail
        commands=$(cat "${uciBatch}")
        secrets=""
        ${lib.concatMapStringsSep "\n" (f: ''
          secrets="$secrets $(${lib.getExe pkgs.sops} -d --output-type json "${f}")"
        '') sopsFiles}

        merged=$(echo "$secrets" | ${lib.getExe pkgs.jq} -s 'add')

        for key in $(echo "$merged" | ${lib.getExe pkgs.jq} -r 'keys[]'); do
          val=$(echo "$merged" | ${lib.getExe pkgs.jq} -r --arg k "$key" '.[$k]')
          commands="''${commands//@''${key}@/$val}"
        done

        ${checkPlaceholders}
        echo "$commands"
      ''
    else
      ''
        set -euo pipefail
        commands=$(cat "${uciBatch}")
        ${checkPlaceholders}
        echo "$commands"
      ''
  );
in
{
  inherit uciBatch command;
}

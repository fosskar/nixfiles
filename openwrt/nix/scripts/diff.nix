# diff script: shows what a deploy would change, computed on the device
{
  pkgs,
  lib,
  deploy,
}:
pkgs.writeShellScriptBin "openwrt-diff" ''
  if [ $# -ne 1 ]; then
    echo "usage: openwrt-diff <device>"
    exit 1
  fi
  exec ${lib.getExe deploy} "$1" --dry-run
''

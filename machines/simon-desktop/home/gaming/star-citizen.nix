{
  inputs,
  pkgs,
  ...
}:
let
  star-citizen = inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.star-citizen.override {
    useUmu = true;
    gameScopeEnable = false;
    gameScopeArgs = [
      "-f"
      "--expose-wayland"
      "--force-grab-cursor"
      "--force-windows-fullscreen"
      "-W 3440"
      "-H 1440"
      "-w 3440"
      "-h 1440"
      "-r 165"
      "--adaptive-sync"
      "--backend=wayland"
      # HDR
      #"--hdr-enabled"
    ];
    preCommands = ''
      ${pkgs.snixembed}/bin/snixembed &
    '';
  };
in
{
  home.packages = [
    star-citizen
  ];
}

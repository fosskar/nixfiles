{
  lib,
  pkgs,
  ...
}:
{

  programs.mcp = {
    enable = true;
    servers = {
      nixos = {
        command = lib.getExe pkgs.mcp-nixos;
      };
    };
  };
}

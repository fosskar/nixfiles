{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.micro ];
      environment.variables.EDITOR = "micro";

      # srvos.server makes vim the default editor
      programs.vim = {
        enable = false;
        defaultEditor = false;
      };
    };
}

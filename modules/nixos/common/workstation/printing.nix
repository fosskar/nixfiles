{
  flake.modules.nixos.workstation =
    { pkgs, ... }:
    {
      services.printing = {
        enable = true;
        # printcap only serves legacy lpd clients; cupsd rejects an empty value,
        # so write it to /run instead of /etc
        extraFilesConf = "Printcap /run/cups/printcap";
      };
      environment.systemPackages = [ pkgs.system-config-printer ];
    };
}

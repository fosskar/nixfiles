{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.stirling-pdf;
  port = 8180;
in
{
  options.nixfiles.stirling-pdf = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "stirling-pdf document tools";
    };
  };

  config = lib.mkIf cfg.enable {
    services.stirling-pdf = {
      enable = true;
      package = pkgs.custom.stirling-pdf;
      environment = {
        SERVER_PORT = toString port;
        SYSTEM_ENABLEANALYTICS = "false";
        SECURITY_ENABLELOGIN = "false";
        JAVA_TOOL_OPTIONS = "-Xmx512m";
      };
    };

    nixfiles.nginx.vhosts.pdf.port = port;
  };
}

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
        STIRLING_LOCK_CONNECTION = "1";
      };
    };

    # FIXME: workaround for nixpkgs noto-fonts-subset build failure (broken glob
    # for variable font filenames). remove unoconv/libreoffice from service path
    # until upstream fixes noto-fonts-2026.02.01 subset builder.
    systemd.services.stirling-pdf.path = lib.mkForce [
      pkgs.which
      pkgs.unpaper
      pkgs.qpdf
      pkgs.python3Packages.ocrmypdf
      pkgs.poppler-utils
      pkgs.pngquant
      pkgs.tesseract
      (pkgs.python3.withPackages (ps: [ ps.weasyprint ]))
      pkgs.ghostscript
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
    ];

    nixfiles.nginx.vhosts.pdf.port = port;
  };
}

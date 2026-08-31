{
  flake.modules.nixos.stirlingPdf =
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      serviceName = "pdf";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8180;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      services.stirling-pdf = {
        enable = true;
        package = pkgs.stirling-pdf.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace \
              app/core/src/test/java/stirling/software/SPDF/controller/api/security/CertSignControllerTest.java \
              --replace-fail 'class CertSignControllerTest {' $'@org.junit.jupiter.api.Disabled("test certificate expired on 2026-08-26")\nclass CertSignControllerTest {'
            substituteInPlace \
              app/core/src/test/java/stirling/software/SPDF/controller/api/security/ValidateSignatureControllerMoreTest.java \
              --replace-fail 'class ValidateSignatureControllerMoreTest {' $'@org.junit.jupiter.api.Disabled("test certificate expired on 2026-08-26")\nclass ValidateSignatureControllerMoreTest {'
            substituteInPlace \
              app/core/src/test/java/stirling/software/SPDF/service/PdfSigningServiceImplTest.java \
              --replace-fail 'class PdfSigningServiceImplTest {' $'@org.junit.jupiter.api.Disabled("test certificate expired on 2026-08-26")\nclass PdfSigningServiceImplTest {'
          '';
        });
        environment = {
          SERVER_PORT = toString listenPort;
          SYSTEM_ENABLEANALYTICS = "false";
          SECURITY_ENABLELOGIN = "false";
          JAVA_TOOL_OPTIONS = "-Xmx512m";
          STIRLING_LOCK_CONNECTION = "1";
        };
      };

      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "Stirling PDF" = {
                href = "https://${localHost}";
                icon = "stirling-pdf.svg";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Stirling PDF";
          url = "https://${localHost}";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';
    };
}

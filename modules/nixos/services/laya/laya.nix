{ inputs, ... }:
{
  flake.modules.nixos.laya =
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      localHost = "laya.${flake-self.domains.local}";
      listenPort = 18091;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
      ps = pkgs.python3Packages;
      # upstream's nix/package.nix pins torch-bin, which needs a newer cuda
      # than nixpkgs ships; cpu torch keeps the gpu free for llama-cpp
      laya = ps.buildPythonPackage {
        pname = "laya";
        version = "0.3.20";
        src = inputs.laya;
        pyproject = true;
        build-system = [ ps.setuptools ];
        dependencies = [
          ps.torch
          ps.transformers
          ps.safetensors
          ps.huggingface-hub
          ps.numpy
        ];
        pythonImportsCheck = [ "laya" ];
      };
      python = pkgs.python3.withPackages (_: [
        laya
        ps.fastapi
        ps.uvicorn
      ]);
      themeCss = pkgs.writeText "theme.css" (
        import ./_theme-css.nix flake-self.themes.${flake-self.theme}
      );
      webRoot = pkgs.runCommand "laya-web" { } ''
        mkdir $out
        cp ${./web/index.html} $out/index.html
        cp ${themeCss} $out/theme.css
      '';
    in
    {
      systemd.services.laya = {
        description = "Laya typed-decision playground";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment.HF_HOME = "/var/lib/laya/huggingface";
        serviceConfig = {
          ExecStart = "${python}/bin/python ${inputs.laya}/examples/server.py --host 127.0.0.1 --port ${toString listenPort} --device cpu";
          DynamicUser = true;
          StateDirectory = "laya";
          Restart = "on-failure";
          RestartSec = 5;

          CapabilityBoundingSet = "";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          UMask = "0077";
        };
      };

      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "Laya" = {
                href = "https://${localHost}";
                icon = "mdi-scale-balance";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "laya";
          url = "https://${localHost}/health";
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      # the upstream playground at / targets developers; serve a plain form
      # instead and pass only the api through
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        handle /predict {
          reverse_proxy ${listenUrl}
        }
        handle /health {
          reverse_proxy ${listenUrl}
        }
        handle {
          root * ${webRoot}
          file_server
        }
      '';
    };
}

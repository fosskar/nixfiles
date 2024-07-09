{
  config,
  lib,
  pkgs,
  ...
}:

####FIXME looks like setui/setgid currently not supported by nix: https://nixos.wiki/wiki/Podman

let
  cfg = config.services.podman;

  inherit (lib) mkOption types;

  podmanPackage = (pkgs.podman.override { inherit (cfg) extraPackages; });

  defaultPolicy = ''
    {
        "default": [
            {
                "type": "insecureAcceptAnything"
            }
        ]
    }
  '';

  podmanSetupScript =
    let
      registriesConf = pkgs.writeText "registries.conf" ''
        [registries.search]
        registries = ['docker.io']
        [registries.block]
        registries = []
      '';
    in
    pkgs.writeScript "podman-setup" ''
      #!${pkgs.runtimeShell}
      # Dont overwrite customised configuration
      if ! test -f ~/.config/containers/policy.json; then
        install -Dm555 ${pkgs.skopeo.src}/default-policy.json ~/.config/containers/policy.json
      fi
      if ! test -f ~/.config/containers/registries.conf; then
        install -Dm555 ${registriesConf} ~/.config/containers/registries.conf
      fi
    '';

in
{
  options.services.podman = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        This option enables Podman, a daemonless container engine for
        developing, managing, and running OCI Containers on your Linux System.

        It is a drop-in replacement for the <command>docker</command> command.
      '';
    };

    dockerSocket = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Make the Podman socket available in place of the Docker socket, so
        Docker tools can find the Podman socket.

        Podman implements the Docker API.
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = lib.literalExpression ''
        [
          pkgs.gvisor
        ]
      '';
      description = ''
        Extra packages to be installed in the Podman wrapper.
      '';
    };

    package = lib.mkOption {
      type = types.package;
      default = podmanPackage;
      internal = true;
      description = ''
        The final Podman package (including extra packages).
      '';
    };

    defaultConfig = mkOption {
      type = types.str;
      default = podmanSetupScript;
      description = ''
        .json content for Podman.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];

        systemd.user = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux) {

          services.podman = {
            Unit = {
              Description = "Podman API Service";
              Requires = [ "podman.socket" ];
              After = [ "podman.socket" ];
              Documentation = "man:podman-system-service(1)";
              StartLimitIntervalSec = 0;
            };
            Service = {
              Type = "exec";
              KillMode = "process";
              Environment = ''LOGGING=" --log-level=info"'';
              ExecStart = [
                ""
                "${cfg.package}/bin/podman $LOGGING system service"
              ];
            };

            Install = {
              WantedBy = [ "default.target" ];
            };
          };

          sockets.podman = {
            Unit = {
              Description = "Podman API Socket";
              Documentation = "man:podman-system-service(1)";
            };
            Socket = {
              ListenStream = "%t/podman/podman.sock";
              SocketMode = 660;
            };
            Install.WantedBy = [ "sockets.target" ];
          };

        };
      }
      (lib.mkIf cfg.dockerSocket {
        home.sessionVariables = {
          "DOCKER_HOST" = "unix:///run/user/$UID/podman/podman.sock";
        };
      })
    ]
  );
}

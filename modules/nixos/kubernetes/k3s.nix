{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.k3sManaged;
  k3cfg = config.services.k3s;
in
{
  options = {
    services.k3sManaged = {
      enable = lib.mkOption {
        default = false;
        type = with lib.types; bool;
        description = ''
          Start a managed k3s.
        '';
      };

      nodeName = lib.mkOption {
        type = with lib.types; uniq str;
        default = config.networking.hostName;
      };

      clusterDomain = lib.mkOption {
        type = with lib.types; uniq str;
        default = "${cfg.nodeName}";
      };

      clusterCIDR = lib.mkOption { type = with lib.types; uniq str; };

      clusterCIDRv6 = lib.mkOption {
        default = "";
        type = with lib.types; uniq str;
      };

      serviceCIDR = lib.mkOption { type = with lib.types; uniq str; };

      serviceCIDRv6 = lib.mkOption {
        default = "";
        type = with lib.types; uniq str;
      };

      clusterDNS = lib.mkOption { type = with lib.types; uniq str; };

      nodeIP = lib.mkOption {
        default = "";
        type = with lib.types; uniq str;
      };

      zfs = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };

      disableLocalPV = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };

      disableTraefik = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };

      disableFlannel = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };

      disableKubeProxy = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };

      disableMetricsServer = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };

      package = lib.mkOption {
        default = pkgs.k3s;
        type = with lib.types; package;
      };

      tlsSAN = lib.mkOption {
        default = "";
        type = with lib.types; uniq str;
      };

      apiServerArgs = lib.mkOption {
        default = [ ];
        type = with lib.types; types.listOf str;
      };

      deviceOwnershipFromSecurityContext = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };
    };
  };

  config =
    let
      finalClusterCIDR =
        cfg.clusterCIDR + (if cfg.clusterCIDRv6 != "" then ",${cfg.clusterCIDRv6}" else "");
      finalServiceCIDR =
        cfg.serviceCIDR + (if cfg.serviceCIDRv6 != "" then ",${cfg.serviceCIDRv6}" else "");
      isAgent = k3cfg.role == "agent";
    in
    lib.mkIf cfg.enable {
      networking.firewall.trustedInterfaces = lib.mkIf (!cfg.disableFlannel) [ "cni0" ];
      environment.systemPackages = [
        cfg.package
        (pkgs.writeShellScriptBin "k3s-reset-node" (builtins.readFile ./k3s-reset-node))
      ];
      services = {
        k3s = {
          enable = true;
          inherit (cfg) package;
          extraFlags = builtins.toString (
            [ "--node-name ${cfg.nodeName}" ]
            ++ (lib.optional (cfg.nodeIP != "") "--node-ip ${cfg.nodeIP}")
            ++ (lib.optional cfg.zfs "--container-runtime-endpoint unix:///run/containerd/containerd.sock")
            ++ (
              if (!isAgent) then
                (
                  [
                    "--cluster-cidr ${finalClusterCIDR}"
                    "--service-cidr ${finalServiceCIDR}"
                    "--cluster-dns ${cfg.clusterDNS}"
                    "--cluster-domain ${cfg.clusterDomain}"
                  ]
                  ++ (lib.optional cfg.disableTraefik "--disable traefik --disable servicelb")
                  ++ (lib.optional (cfg.tlsSAN != "") "--tls-san ${cfg.tlsSAN}")
                  ++ (lib.optional cfg.disableLocalPV "--disable local-storage")
                  ++ (lib.optional cfg.disableMetricsServer "--disable metrics-server")
                  ++ (
                    if cfg.disableFlannel then
                      [ "--flannel-backend none --disable-network-policy" ]
                    else
                      [ "--flannel-backend host-gw" ]
                  )
                  ++ (lib.optional cfg.disableKubeProxy "--disable-kube-proxy")
                  ++ (lib.optional (cfg.apiServerArgs != "") (
                    toString (map (s: "--kube-apiserver-arg ${s}") cfg.apiServerArgs)
                  ))
                )
              else
                [
                  "--server https://${cfg.nodeIP}:6443" # Connect to the control node
                  "--node-label node-role.kubernetes.io/worker=true"
                ]
            )
          );
        };
      };

      system.activationScripts = lib.mkIf cfg.zfs {
        sbinZfs = {
          text = ''
            mkdir -p /sbin
            ln -sf ${pkgs.zfs}/bin/zfs /sbin/zfs
          '';
          deps = [ ];
        };
      };

      virtualisation.containerd = lib.mkIf cfg.zfs (
        let
          deviceOwnership =
            if cfg.deviceOwnershipFromSecurityContext then
              { plugins."io.containerd.grpc.v1.cri".device_ownership_from_security_context = true; }
            else
              { };
          hostedCni = {
            plugins."io.containerd.grpc.v1.cri".cni = {
              bin_dir = "/opt/cni/bin/";
              conf_dir = "/etc/cni/net.d/";
            };
          };
          nixCni =
            let
              fullCNIPlugins = pkgs.buildEnv {
                name = "full-cni";
                paths = with pkgs; [
                  cni-plugins
                  cni-plugin-flannel
                ];
              };
            in
            {
              plugins."io.containerd.grpc.v1.cri".cni = {
                bin_dir = "${fullCNIPlugins}/bin";
                conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d/";
              };
            };
        in
        {
          enable = true;
          settings = lib.recursiveUpdate deviceOwnership (if cfg.disableFlannel then hostedCni else nixCni);
        }
      );
      systemd.services.k3s = {
        wants = [ "containerd.service" ];
        after = [ "containerd.service" ];
      };
    };
}

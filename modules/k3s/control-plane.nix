{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.k3s.controlPlane;
in
{
  options.k3s.controlPlane = {
    enable = mkEnableOption "shared K3s control-plane settings";

    clusterInit = mkOption {
      type = types.bool;
      default = false;
      description = "Initial node bootstraps the etcd cluster.";
    };

    nodeName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Node name reported to K3s.";
    };

    nodeIp = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "IP address used for node communication.";
    };

    tlsSans = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional TLS SAN values. The node IP is added automatically.";
    };

    serverAddr = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "API server URL to join when not bootstrapping.";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra flags appended to the generated control-plane defaults.";
    };

    ciliumChart = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Fetch the Cilium Helm chart to mirror the old manual step.";
      };

      url = mkOption {
        type = types.str;
        default = "https://helm.cilium.io/cilium-1.17.1.tgz";
        description = "Cilium Helm chart URL.";
      };

      sha256 = mkOption {
        type = types.str;
        default = "sha256-OB3k+PTF6s5nfTQmqo2JbvjSMYwr9NEXLJlTNFt0RHE=";
        description = "Expected sha256 for the Cilium chart.";
      };
    };
  };

  config = mkIf cfg.enable (
    let
      baseFlags = [
        "--data-dir=/var/lib/rancher/k3s"
        "--write-kubeconfig=/root/.kube/config"
        "--disable=traefik"
        "--disable-network-policy"
        "--disable=servicelb"
        "--flannel-backend=none"
        "--etcd-expose-metrics"
        "--secrets-encryption"
        "--disable-kube-proxy"
        "--egress-selector-mode=cluster"
        "--kube-scheduler-arg bind-address=0.0.0.0"
        "--kube-controller-manager-arg bind-address=0.0.0.0"
        "--disable local-storage"
      ];
      tlsSans = lib.unique (lib.optional (cfg.nodeIp != null) cfg.nodeIp ++ cfg.tlsSans);
      nodeFlags = [
        "--node-name=${cfg.nodeName}"
      ]
      ++ lib.optionals (cfg.nodeIp != null) [ "--node-ip=${cfg.nodeIp}" ]
      ++ map (san: "--tls-san=${san}") tlsSans;
    in
    {
      assertions = [
        {
          assertion = cfg.nodeName != null;
          message = "k3s.controlPlane.nodeName must be set when enabling the control-plane module.";
        }
      ];

      services.k3s = {
        enable = true;
        role = "server";
        inherit (cfg) clusterInit;
        serverAddr = mkIf (cfg.serverAddr != null) cfg.serverAddr;
        extraFlags = baseFlags ++ nodeFlags ++ cfg.extraFlags;
        charts = mkIf cfg.ciliumChart.enable {
          cilium = pkgs.fetchurl {
            inherit (cfg.ciliumChart) url sha256;
          };
        };
      };
    }
  );
}

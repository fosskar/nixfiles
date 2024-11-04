{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.k3sManaged;
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
      role = lib.mkOption {
        default = "server";
        type = lib.types.enum [
          "server"
          "agent"
        ];
      };

      serverAddr = lib.mkOption {
        default = "";
        type = with lib.types; uniq str;
      };

      clusterInit = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };

      tokenFile = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.path;
      };

      kubeconfigFile = lib.mkOption {
        type = with lib.types; str;
        default = "/root/.kube/config";
      };

      nodeName = lib.mkOption {
        type = with lib.types; uniq str;
        default = config.networking.hostName;
      };

      clusterDomain = lib.mkOption {
        type = with lib.types; uniq str;
        default = "${cfg.nodeName}";
      };

      clusterCIDR = lib.mkOption {
        default = "10.42.0.0/16";
        type = with lib.types; uniq str;
      };

      clusterCIDRv6 = lib.mkOption {
        default = "";
        type = with lib.types; uniq str;
      };

      serviceCIDR = lib.mkOption {
        default = "10.43.0.0/16";
        type = with lib.types; uniq str;
      };

      serviceCIDRv6 = lib.mkOption {
        default = "";
        type = with lib.types; uniq str;
      };

      clusterDNS = lib.mkOption {
        default = "10.43.0.10";
        type = with lib.types; uniq str;
      };

      nodeIP = lib.mkOption {
        default = "";
        type = with lib.types; uniq str;
      };

      disableLocalPV = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };

      disableTraefik = lib.mkOption {
        default = false;
        type = with lib.types; bool;
      };

      disableServicelb = lib.mkOption {
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

      etcdMetrics = lib.mkOption {
        default = true;
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
    };
  };
  config =
    let
      finalClusterCIDR =
        cfg.clusterCIDR + (if cfg.clusterCIDRv6 != "" then ",${cfg.clusterCIDRv6}" else "");
      finalServiceCIDR =
        cfg.serviceCIDR + (if cfg.serviceCIDRv6 != "" then ",${cfg.serviceCIDRv6}" else "");
      isAgent = cfg.role == "agent";
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
          inherit (cfg) clusterInit;
          inherit (cfg) role;
          tokenFile = if cfg.tokenFile != null then cfg.tokenFile else null;
          serverAddr = if isAgent then "https://${cfg.serverAddr}:6443" else "";
          extraFlags = builtins.toString (
            [
              "--node-name ${cfg.nodeName}"
              "--data-dir /var/lib/rancher/k3s"
            ]
            ++ (lib.optional (cfg.nodeIP != "") "--node-ip ${cfg.nodeIP}")
            ++ (
              if (!isAgent) then
                (
                  [
                    "--write-kubeconfig=${cfg.kubeconfigFile}"
                    "--cluster-cidr ${finalClusterCIDR}"
                    "--service-cidr ${finalServiceCIDR}"
                    "--cluster-dns ${cfg.clusterDNS}"
                    "--cluster-domain ${cfg.clusterDomain}"
                    "--etcd-snapshot-schedule-cron '0 */12 * * *'"
                  ]
                  ++ (lib.optional (cfg.clusterInit && cfg.etcdMetrics) "--etcd-expose-metrics=true")
                  ++ (lib.optional cfg.disableTraefik "--disable traefik")
                  ++ (lib.optional cfg.disableServicelb "--disable servicelb")
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
                  "--node-label worker=true"
                ]
            )
          );
        };
      };
      systemd = {
        services.k3s = {
          wants = [ "containerd.service" ];
          after = [ "containerd.service" ];
        };
        tmpfiles.rules = lib.mkIf (cfg.disableFlannel && isAgent) [
          "L+ /opt/cni/bin - - - - /var/lib/rancher/k3s/data/current/bin"
          # If you have disabled flannel, you will have to create the directory via a tmpfiles rule
          "D /var/lib/rancher/k3s/agent/etc/cni/net.d 0751 root root - -"
          # Link the CNI config directory
          "L+ /etc/cni/net.d - - - - /var/lib/rancher/k3s/agent/etc/cni/net.d"
        ];
      };
    };
}

{
  # single-node talos kubernetes playground in a qemu vm. the host only
  # provides the environment — bridge, nat, dhcp, a persistent disk — while
  # the cluster itself is declared talos-side via machineconfig:
  #
  #   talosctl gen config playground https://10.20.2.2:6443 --config-patch @/etc/talos-vm/patch.yaml
  #   talosctl apply-config --insecure -n 10.20.2.2 --file controlplane.yaml
  #   talosctl bootstrap -n 10.20.2.2 -e 10.20.2.2
  #   talosctl kubeconfig -n 10.20.2.2 -e 10.20.2.2
  #   flux bootstrap github --owner=<you> --repository=<gitops> --path=clusters/talos
  flake.modules.nixos.talosVm =
    {
      config,
      options,
      lib,
      pkgs,
      ...
    }:
    let
      version = "1.13.5";
      iso = pkgs.fetchurl {
        url = "https://github.com/siderolabs/talos/releases/download/v${version}/metal-amd64.iso";
        hash = "sha256-FRGuhdsHaxsro8OPvS1sVS8loZi2XRyTqtEjbQRzy9c=";
      };
      bridge = "talosbr0";
      tap = "talos0";
      hostIp = "10.20.2.1";
      vmIp = "10.20.2.2";
      vmMac = "52:54:00:74:61:6c";
      vmHostname = "kube-${config.networking.hostName}";
      # single node: control plane must also schedule workloads; the qemu
      # disk is virtio, so the installer must target vda, not the sda default.
      # hostname lives in its own HostnameConfig document; auto must be
      # switched off explicitly, the generated default is auto: stable
      configPatch = pkgs.writeText "talos-patch.yaml" ''
        machine:
          install:
            disk: /dev/vda
        cluster:
          allowSchedulingOnControlPlanes: true
        ---
        apiVersion: v1alpha1
        kind: HostnameConfig
        auto: "off"
        hostname: ${vmHostname}
      '';
    in
    {
      config = {
        systemd.network = {
          netdevs = {
            "10-${bridge}".netdevConfig = {
              Name = bridge;
              Kind = "bridge";
            };
            "11-${tap}" = {
              netdevConfig = {
                Name = tap;
                Kind = "tap";
              };
              tapConfig = {
                User = "root";
                Group = "root";
              };
            };
          };
          networks = {
            "10-${bridge}" = {
              matchConfig.Name = bridge;
              networkConfig = {
                Address = "${hostIp}/24";
                ConfigureWithoutCarrier = true;
                DHCPServer = true;
              };
              dhcpServerConfig = {
                EmitDNS = true;
                DNS = builtins.head config.networking.nameservers;
              };
              dhcpServerStaticLeases = [
                {
                  MACAddress = vmMac;
                  Address = vmIp;
                }
              ];
            };
            "11-${tap}" = {
              matchConfig.Name = tap;
              networkConfig.Bridge = bridge;
            };
          };
        };

        networking.nat = {
          enable = true;
          externalInterface = "bond0";
          internalInterfaces = [ bridge ];
        };

        # talos maintenance mode relies on dhcp; guests resolve via the
        # host's upstream resolver, reached through nat
        networking.firewall.interfaces.${bridge}.allowedUDPPorts = [ 67 ];

        # like agent-vm: internet stays open, private ranges are dropped so
        # playground workloads cannot walk the lan or the netbird mesh; dns
        # to the router passes because dhcp hands out that resolver
        networking.firewall.extraForwardRules = ''
          iifname "${bridge}" ip daddr ${builtins.head config.networking.nameservers} udp dport 53 accept
          iifname "${bridge}" ip daddr ${builtins.head config.networking.nameservers} tcp dport 53 accept
          iifname "${bridge}" ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10 } drop
          iifname "${bridge}" accept
          oifname "${bridge}" ct state established,related accept
        '';

        systemd.services.talos-vm = {
          description = "talos kubernetes playground vm";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          preStart = ''
            if [ ! -f /var/lib/talos-vm/disk.qcow2 ]; then
              ${lib.getExe' pkgs.qemu_kvm "qemu-img"} create -f qcow2 /var/lib/talos-vm/disk.qcow2 20G
            fi
          '';
          serviceConfig = {
            StateDirectory = "talos-vm";
            # bios falls through the blank disk to the iso on first boot;
            # after talos installs itself the disk wins
            ExecStart = lib.concatStringsSep " " [
              (lib.getExe' pkgs.qemu_kvm "qemu-system-x86_64")
              "-machine q35,accel=kvm"
              "-cpu host"
              "-smp 2"
              "-m 4096"
              "-nographic"
              "-drive file=/var/lib/talos-vm/disk.qcow2,if=virtio,format=qcow2"
              "-cdrom ${iso}"
              "-boot order=cd"
              "-netdev tap,id=net0,ifname=${tap},script=no,downscript=no"
              "-device virtio-net-pci,netdev=net0,mac=${vmMac}"
              "-device virtio-rng-pci"
            ];
            Restart = "on-failure";
            MemoryMax = "6G";
            CPUQuota = "300%";
            CPUWeight = 20;
          };
        };

        environment.systemPackages = [
          pkgs.talosctl
          pkgs.kubectl
          pkgs.fluxcd
        ];

        environment.etc."talos-vm/patch.yaml".source = configPatch;
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          "/var/lib/talos-vm"
        ];
      };
    };
}

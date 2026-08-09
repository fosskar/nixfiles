{
  #   talosctl gen config playground https://10.20.2.2:6443 --config-patch @/etc/talos-vm/patch.yaml
  #   talosctl apply-config --insecure -n 10.20.2.2 --file controlplane.yaml
  #   talosctl bootstrap -n 10.20.2.2 -e 10.20.2.2
  #   talosctl kubeconfig -n 10.20.2.2 -e 10.20.2.2
  #
  # remote: talos api kube-<host>.<domain>:50000, kube api kube-<host>.<domain>:16443
  flake.modules.nixos.talosVm =
    {
      config,
      flake-self,
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
      vmFqdn = "${vmHostname}.${flake-self.domains.local}";
      configPatch = pkgs.writeText "talos-patch.yaml" ''
        machine:
          install:
            disk: /dev/vda
          certSANs:
            - ${vmFqdn}
        cluster:
          allowSchedulingOnControlPlanes: true
          apiServer:
            certSANs:
              - ${vmFqdn}
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
          # yggdrasil owns 6443 on the host address
          forwardPorts = [
            {
              sourcePort = 16443;
              destination = "${vmIp}:6443";
              proto = "tcp";
            }
            {
              sourcePort = 50000;
              destination = "${vmIp}:50000";
              proto = "tcp";
            }
          ];
        };

        networking.firewall.interfaces.${bridge}.allowedUDPPorts = [ 67 ];

        # private ranges dropped so playground workloads cannot walk the lan
        networking.firewall.extraForwardRules = ''
          iifname "${bridge}" meta nfproto ipv6 drop
          oifname "${bridge}" tcp dport { 6443, 50000 } accept
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

        # manual trigger after patch changes: systemctl start talos-vm-config
        systemd.services.talos-vm-config = {
          unitConfig.ConditionPathExists = "/var/lib/talos-vm/talosconfig";
          serviceConfig.Type = "oneshot";
          script = ''
            exec ${lib.getExe pkgs.talosctl} --talosconfig /var/lib/talos-vm/talosconfig \
              -n ${vmIp} -e ${vmIp} patch machineconfig --patch @${configPatch}
          '';
        };

        # --- backup ---

        # the qcow2 holds etcd but is torn if copied while the vm runs. the
        # etcd snapshot is the supported consistent export; secrets.yaml is the
        # cluster pki and cannot be regenerated from the config.
        clan.core.state.talos-vm = {
          folders = [ "/var/backup/talos-vm" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.talosctl
                pkgs.coreutils
                pkgs.systemd
              ]
            }
            mkdir -p /var/backup/talos-vm
            cp /var/lib/talos-vm/secrets.yaml /var/lib/talos-vm/controlplane.yaml \
              /var/lib/talos-vm/talosconfig /var/backup/talos-vm/
            # a stopped vm has nothing to snapshot; a running one that fails to
            # answer is a real error and must fail the job
            if systemctl is-active --quiet talos-vm.service; then
              talosctl --talosconfig /var/lib/talos-vm/talosconfig -n ${vmIp} -e ${vmIp} \
                etcd snapshot /var/backup/talos-vm/etcd.snapshot
            fi
          '';
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

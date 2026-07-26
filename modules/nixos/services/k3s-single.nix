{
  flake.modules.nixos.k3sSingle =
    {
      options,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        services.k3s = {
          enable = true;
          role = "server";
          # caddy owns 80/443 on the host; klipper-lb and traefik would fight for them
          extraFlags = [
            "--disable=traefik"
            "--disable=servicelb"
            "--write-kubeconfig=/var/lib/rancher/k3s/k3s.yaml"
          ];
        };

        environment.systemPackages = [
          pkgs.fluxcd
          pkgs.kubectl
        ];

        environment.variables.KUBECONFIG = "/var/lib/rancher/k3s/k3s.yaml";

        # /etc/rancher/node/password path is hardcoded in k3s; keep /etc free of
        # mutable state by pointing it into the persisted data dir
        systemd.tmpfiles.rules = [
          "d /var/lib/rancher/node 0700 root root -"
          "L+ /etc/rancher/node - - - - /var/lib/rancher/node"
        ];
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          "/var/lib/rancher"
        ];
      };
    };
}

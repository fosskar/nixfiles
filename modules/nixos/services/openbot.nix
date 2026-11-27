{
  # openbot ships its headless server only as an apt install script and an
  # OCI image; the flake packages just the desktop AppImage. sign in once
  # with `podman exec -it openbot openbot login`.
  flake.modules.nixos.openbot =
    {
      flake-self,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      version = "0.80.0";
      dataDir = "/var/lib/openbot";
      # the electron sandbox needs user namespaces, which the default profile refuses
      seccompProfile = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/nightly-labs/openbot/v${version}/docker/seccomp.json";
        hash = "sha256-ZlKJ5qHEEEX1UWbQsBmTySn3HfeOOjsmTzJSu44LPZ4=";
      };
    in
    {
      imports = [ flake-self.modules.nixos.podman ];

      config = {
        # the image runs as uid/gid 1000 with /data as its home
        systemd.tmpfiles.rules = [ "d ${dataDir} 0700 1000 1000 -" ];

        virtualisation.oci-containers = {
          backend = "podman";
          containers.openbot = {
            image = "ghcr.io/nightly-labs/openbot:${version}@sha256:1dbcbb4620f2fdd0f3bc21e14152b4516ef98ac1d90a8a9414a38520162bf562";
            volumes = [ "${dataDir}:/data" ];
            extraOptions = [
              "--security-opt=seccomp=${seccompProfile}"
              "--security-opt=no-new-privileges"
              "--shm-size=1g"
              "--stop-timeout=60"
            ];
          };
        };
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = dataDir;
            user = "1000";
            group = "1000";
            mode = "0700";
          }
        ];
      };
    };
}

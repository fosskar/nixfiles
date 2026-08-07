{ lib }:
{
  type = lib.types.listOf (
    lib.types.submodule {
      options = {
        listenAddress = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };
        listenPort = lib.mkOption {
          type = lib.types.port;
        };
        guestPort = lib.mkOption {
          type = lib.types.port;
        };
      };
    }
  );

  endpointsOf =
    instances:
    lib.concatLists (
      lib.mapAttrsToList (
        _: cfg: map (forward: "${forward.listenAddress}:${toString forward.listenPort}") cfg.forwards
      ) instances
    );
}

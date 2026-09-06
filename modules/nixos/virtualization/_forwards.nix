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

  unitName = name: forward: "${name}-forward-${toString forward.listenPort}";

  # the relay only reaches the sandbox's own address; the bridge is the
  # only network it can see
  hardening = ip: {
    StandardInput = "socket";
    StandardError = "journal";
    DynamicUser = true;
    RestrictAddressFamilies = [ "AF_INET" ];
    IPAddressAllow = [ "${ip}/32" ];
    IPAddressDeny = "any";
    CapabilityBoundingSet = "";
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
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
    ProtectSystem = "strict";
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    UMask = "0077";
  };
}

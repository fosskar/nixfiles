_: {
  flake.modules.nixos.hermesMatrix =
    { config, lib, ... }:
    let
      cfg = config.services.hermes-agent.matrix;
    in
    {
      options.services.hermes-agent.matrix = {
        homeserver = lib.mkOption {
          type = lib.types.str;
          default = "https://matrix.fosskar.eu";
        };
        userId = lib.mkOption {
          type = lib.types.str;
          example = "@hermes:example.org";
        };
        deviceId = lib.mkOption {
          type = lib.types.str;
          default = "HERMES_BOT";
        };
        allowedUsers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "mxids allowed to talk to the agent.";
        };
      };

      config.services.hermes-agent.environment = {
        MATRIX_HOMESERVER = cfg.homeserver;
        MATRIX_USER_ID = cfg.userId;
        MATRIX_DEVICE_ID = cfg.deviceId;
        MATRIX_ALLOWED_USERS = lib.concatStringsSep "," cfg.allowedUsers;
        # fail closed rather than silently falling back to plaintext when
        # crypto cannot initialise. MATRIX_ENCRYPTION is the deprecated alias
        MATRIX_E2EE_MODE = "required";
      };
    };
}

{ inputs, ... }:
{
  flake.modules.nixos.hermesBuzz =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.hermes-agent.buzz;
      sidecars = inputs.buzz-flake.packages.${pkgs.stdenv.hostPlatform.system}.buzz-sidecars;
    in
    {
      options.services.hermes-agent.buzz = {
        relayUrl = lib.mkOption {
          type = lib.types.str;
          default = "wss://buzz.${flake-self.domains.public}";
        };
        channels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "channel UUIDs to watch; empty = all joined channels.";
        };
        homeChannel = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "channel UUID for cron and notification delivery.";
        };
        allowedUsers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "npubs or hex pubkeys allowed to talk to the agent.";
        };
        replyInThread = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "thread replies under the triggering message; false posts flat to the channel timeline.";
        };
      };

      # upstream's recommended buzz defaults: only the final answer reaches the
      # channel, not the tool log. telegram and email already default to this
      config.services.hermes-agent.settings.display.platforms.buzz = {
        interim_assistant_messages = false;
        tool_progress = "off";
      };

      config.services.hermes-agent.environment = {
        BUZZ_RELAY_URL = cfg.relayUrl;
        # pinned store path; the adapter's fallback chain (PATH, ~/bin/buzz)
        # never fires
        BUZZ_CLI_PATH = lib.getExe' sidecars "buzz";
        BUZZ_ALLOWED_USERS = lib.concatStringsSep "," cfg.allowedUsers;
        BUZZ_ALLOW_ALL_USERS = "false";
        # in channels only respond when addressed; DMs always dispatch
        BUZZ_REQUIRE_MENTION = "true";
        BUZZ_REPLY_IN_THREAD = lib.boolToString cfg.replyInThread;
      }
      // lib.optionalAttrs (cfg.channels != [ ]) {
        BUZZ_CHANNELS = lib.concatStringsSep "," cfg.channels;
      }
      // lib.optionalAttrs (cfg.homeChannel != null) {
        BUZZ_HOME_CHANNEL = cfg.homeChannel;
      };
    };
}

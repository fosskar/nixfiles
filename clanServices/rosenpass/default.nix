# rosenpass: post-quantum key exchange for wireguard
#
# adds rosenpass PSK rotation on top of an existing clan wireguard service.
# references wireguard keys/interface via clanLib.getPublicValue.
#
# requires: clan-core/wireguard service to be configured for the same machines.
{ clanLib, ... }:
{
  _class = "clan.service";
  manifest.name = "rosenpass";
  manifest.description = "post-quantum key exchange for wireguard via rosenpass";
  manifest.categories = [
    "Network"
    "Security"
  ];

  roles.peer = {
    description = "wireguard peer that participates in rosenpass key exchange";
    interface =
      { lib, ... }:
      {
        options.wireguardInstance = lib.mkOption {
          type = lib.types.str;
          default = "wireguard";
          description = "name of the clan wireguard instance to attach rosenpass to";
        };
        options.listenPort = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          description = "rosenpass listen port (set on publicly reachable machines)";
        };
        options.endpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "rosenpass endpoint (host:port) of this machine, as seen by peers";
        };
      };

    perInstance =
      {
        settings,
        instanceName,
        roles,
        machine,
        ...
      }:
      {
        nixosModule =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          let
            wgInstance = settings.wireguardInstance;
            allPeers = lib.filterAttrs (name: _: name != machine.name) roles.peer.machines;
          in
          {
            # generate rosenpass key pair
            clan.core.vars.generators."rosenpass-${instanceName}" = {
              files.pqpk.secret = false;
              files.pqsk = { };

              runtimeInputs = [ pkgs.rosenpass ];

              script = ''
                rosenpass gen-keys --secret-key "$out/pqsk" --public-key "$out/pqpk"
              '';
            };

            services.rosenpass = {
              enable = true;
              defaultDevice = wgInstance;
              settings = {
                public_key = config.clan.core.vars.generators."rosenpass-${instanceName}".files.pqpk.path;
                secret_key = config.clan.core.vars.generators."rosenpass-${instanceName}".files.pqsk.path;
                listen = lib.optional (settings.listenPort != null) "0.0.0.0:${toString settings.listenPort}";

                peers = lib.mapAttrsToList (name: value: {
                  # remote rosenpass public key
                  public_key = clanLib.getPublicValue {
                    flake = config.clan.core.settings.directory;
                    machine = name;
                    generator = "rosenpass-${instanceName}";
                    file = "pqpk";
                  };

                  # remote wireguard public key (for PSK injection)
                  peer = clanLib.getPublicValue {
                    flake = config.clan.core.settings.directory;
                    machine = name;
                    generator = "wireguard-keys-${wgInstance}";
                    file = "publickey";
                  };

                  # endpoint if the remote peer has one
                  endpoint = if value.settings.endpoint != null then value.settings.endpoint else null;
                }) allPeers;
              };
            };

            # persist rosenpass state
            nixfiles.persistence.directories = [
              "/var/lib/rosenpass"
            ];
          };
      };
  };
}

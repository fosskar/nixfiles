{
  lib,
  nodeContext ? null,
  hostRegistry ? null,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;

  ensure =
    name: value:
    if value != null then
      value
    else
      throw "modules/meta/default.nix: missing required specialArg '${name}'";

  ctx = ensure "nodeContext" nodeContext;
  registry = ensure "hostRegistry" hostRegistry;
in
{
  options.node = {
    name = mkOption {
      type = types.str;
      readOnly = true;
      description = "Fully-qualified node identifier (e.g. hypervisor.guest).";
    };
    hostName = mkOption {
      type = types.str;
      readOnly = true;
      description = "Hostname applied to networking.hostName.";
    };
    hostPath = mkOption {
      type = types.path;
      readOnly = true;
      description = "Absolute path to this node's directory within the repository.";
    };
    secretsDir = mkOption {
      type = types.path;
      readOnly = true;
      description = "Repository path containing secrets for this node.";
    };
    hostPubKeyPath = mkOption {
      type = types.path;
      readOnly = true;
      description = "Path to the SSH host public key tracked in the repository.";
    };
    parentNodeName = mkOption {
      type = types.nullOr types.str;
      default = null;
      readOnly = true;
      description = "If this node is a guest, reference to the hypervisor node.";
    };
    guestName = mkOption {
      type = types.nullOr types.str;
      default = null;
      readOnly = true;
      description = "Guest identifier relative to the parent node.";
    };
    isGuest = mkOption {
      type = types.bool;
      readOnly = true;
      description = "Whether this node represents a guest running on another node.";
    };
    secretsRelative = mkOption {
      type = types.str;
      readOnly = true;
      description = "Relative path segment used to store generated secrets.";
    };
    tags = mkOption {
      type = types.listOf types.str;
      readOnly = true;
      description = "List of tags, typically containing the top-level host name.";
    };
    registry = mkOption {
      type = types.attrsOf types.attrs;
      readOnly = true;
      description = "Inventory of all node contexts derived from hosts/.";
    };
    meta = mkOption {
      type = types.attrs;
      readOnly = true;
      description = "Raw metadata collected for this node.";
    };
  };

  config.node = {
    name = ctx.nodeName;
    inherit (ctx) hostName;
    inherit (ctx) hostPath;
    inherit (ctx) secretsDir;
    inherit (ctx) hostPubKeyPath;
    inherit (ctx) parentNodeName;
    inherit (ctx) guestName;
    inherit (ctx) isGuest;
    inherit (ctx) secretsRelative;
    inherit (ctx) tags;
    inherit registry;
    meta = ctx;
  };
}

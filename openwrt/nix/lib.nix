# pure nix UCI serializer
# converts nix attrsets to UCI batch commands
#
# format follows Mic92/openwrt-nix conventions:
#   - named sections: attrset with _type
#   - anonymous sections: list of attrsets with _type
#   - list values: nix lists become add_list commands
#   - secrets: @placeholder@ patterns for runtime substitution
{ lib }:
let
  inherit (builtins)
    isList
    isAttrs
    isString
    isBool
    isInt
    isFloat
    typeOf
    length
    ;
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
    mapAttrsToList
    filterAttrs
    imap0
    ;

  # escape single quotes in UCI values
  escapeUci = s: lib.replaceStrings [ "'" ] [ "'\"'\"'" ] (toString s);

  # serialize a single option value to UCI batch command(s)
  serializeValue =
    key: val:
    if isList val then
      concatMapStringsSep "\n" (v: "add_list ${key}='${escapeUci v}'") val
    else if isBool val then
      "set ${key}='${if val then "1" else "0"}'"
    else if isInt val || isFloat val then
      "set ${key}='${toString val}'"
    else if isString val then
      "set ${key}='${escapeUci val}'"
    else
      throw "${key}: unsupported type ${typeOf val}";

  # serialize a named section (attrset with _type)
  serializeNamedSection =
    config: name: section:
    let
      type = section._type or (throw "${config}.${name}: missing _type");
      opts = filterAttrs (k: _: k != "_type") section;
      optLines = mapAttrsToList (k: v: serializeValue "${config}.${name}.${k}" v) opts;
    in
    concatStringsSep "\n" (
      [
        "delete ${config}.${name}"
        "set ${config}.${name}=${type}"
      ]
      ++ optLines
    );

  # serialize anonymous/list sections (list of attrsets with _type)
  serializeListSections =
    config: typeName: sections:
    let
      # delete existing anonymous entries — always delete [0] since indices shift down
      # 30 iterations handles any reasonable existing count
      deletes = lib.genList (_: "delete ${config}.@${typeName}[0]") 30;
      adds = lib.genList (_: "add ${config} ${typeName}") (length sections);
      setOpts = imap0 (
        idx: section:
        let
          type = section._type or (throw "${config}.@${typeName}[${toString idx}]: missing _type");
          opts = filterAttrs (k: _: k != "_type") section;
          optLines = mapAttrsToList (
            k: v: serializeValue "${config}.@${typeName}[${toString idx}].${k}" v
          ) opts;
        in
        concatStringsSep "\n" ([ "set ${config}.@${typeName}[${toString idx}]=${type}" ] ++ optLines)
      ) sections;
    in
    concatStringsSep "\n" (deletes ++ adds ++ setOpts);

  # serialize a full config file (e.g., "network", "wireless", "firewall")
  serializeConfig =
    config: sections:
    concatStringsSep "\n" (
      mapAttrsToList (
        name: section:
        if isList section then
          serializeListSections config name section
        else if isAttrs section then
          serializeNamedSection config name section
        else
          throw "${config}.${name}: expected attrset or list, got ${typeOf section}"
      ) sections
    );

  # serialize all UCI settings to batch commands
  serializeUci = settings: concatStringsSep "\n" (mapAttrsToList serializeConfig settings);
in
{
  inherit serializeUci;
}

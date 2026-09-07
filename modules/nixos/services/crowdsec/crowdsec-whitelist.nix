{
  flake.modules.nixos.crowdsecWhitelist =
    {
      config,
      lib,
      flake-self,
      ...
    }:
    let
      clanMeshIPs = lib.pipe config.networking.extraHosts [
        (lib.splitString "\n")
        (builtins.filter (line: line != ""))
        (map (line: lib.head (lib.splitString " " line)))
        lib.unique
      ];
      publicIP = lib.attrByPath [ config.networking.hostName "wan" ] null flake-self.hosts;
      trustedIPs = clanMeshIPs ++ lib.optional (publicIP != null) publicIP;
      # one overflow can mix vhosts, so a per-vhost all() never matches;
      # the predicate is the union and any unlisted event still bans
      benignProbing = [
        ".GetMeta('http_hostname') == 'niks3.${flake-self.domains.public}'"
        ".GetMeta('http_hostname') == 'matrix.${flake-self.domains.public}' && .GetMeta('http_path') startsWith '/_matrix/'"
      ];
    in
    {
      services.crowdsec.localConfig = {
        parsers.s02Enrich = lib.mkIf (trustedIPs != [ ]) [
          {
            name = "nixfiles/clan-whitelist";
            description = "whitelist clan mesh network IPs";
            whitelist = {
              reason = "clan mesh network";
              ip = trustedIPs;
            };
          }
        ];
        postOverflows.s01Whitelist = [
          {
            name = "nixfiles/probing-whitelist";
            description = "nix cache and matrix clients burst 404s (narinfo/nar cache misses, dead remote media thumbnails, optional endpoints) that http-probing misreads as scanning";
            whitelist = {
              reason = "404 bursts are normal binary cache and matrix client behavior";
              expression = [
                "evt.Overflow.Alert.Scenario == 'crowdsecurity/http-probing' && all(evt.Overflow.Alert.Events, {${
                  lib.concatMapStringsSep " || " (cond: "(${cond})") benignProbing
                }})"
              ];
            };
          }
        ];
      };
    };
}

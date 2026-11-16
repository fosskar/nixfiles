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
      services.crowdsec.settings = {
        parsers.s02Enrich = [
          {
            name = "nixfiles/clan-whitelist";
            description = "whitelist clan mesh network IPs and loopback";
            whitelist = {
              reason = "clan mesh network or loopback";
              ip = trustedIPs;
              # tor and p2p-ssh-iroh deliver every ssh client from loopback; a
              # loopback ban would cut traefik from netbird-server and lapi
              cidr = [
                "127.0.0.0/8"
                "::1/128"
              ];
            };
          }
          {
            name = "nixfiles/sshd-injected-ip-whitelist";
            description = "drop sshd events whose client-chosen user name carries an address";
            whitelist = {
              # sshd appends the real peer after the user name; an earlier address came from the client
              reason = "sshd line holds more than one address";
              expression = [
                "evt.Meta.service == 'ssh' && evt.Parsed.message matches '(?:[0-9]{1,3}[.]){3}[0-9]{1,3}.* (?:(?:[0-9]{1,3}[.]){3}[0-9]{1,3}|[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}:[0-9a-fA-F:]*)'"
              ];
            };
          }
        ];
        postOverflows.s01Whitelist = [
          {
            name = "nixfiles/probing-whitelist";
            description = "nix cache and matrix clients burst 404s (narinfo/nar cache misses, dead remote media thumbnails, optional endpoints) and 200s (cache hits) that http-probing and http-crawl-non_statics misread as scanning";
            whitelist = {
              reason = "request bursts are normal binary cache and matrix client behavior";
              expression = [
                "evt.Overflow.Alert.Scenario in ['crowdsecurity/http-probing', 'crowdsecurity/http-crawl-non_statics'] && all(evt.Overflow.Alert.Events, {${
                  lib.concatMapStringsSep " || " (cond: "(${cond})") benignProbing
                }})"
              ];
            };
          }
        ];
      };
    };
}

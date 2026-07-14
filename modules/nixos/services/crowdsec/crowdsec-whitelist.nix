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
      # postoverflow (not parser-stage) whitelists: only defuse http-probing,
      # keep other scenarios (brute-force etc.) intact for these vhosts
      probingWhitelist = name: description: reason: eventCond: {
        inherit name description;
        whitelist = {
          inherit reason;
          expression = [
            "evt.Overflow.Alert.Scenario == 'crowdsecurity/http-probing' && all(evt.Overflow.Alert.Events, {${eventCond}})"
          ];
        };
      };
    in
    {
      services.crowdsec.localConfig = {
        parsers.s02Enrich = lib.mkIf (clanMeshIPs != [ ]) [
          {
            name = "nixfiles/clan-whitelist";
            description = "whitelist clan mesh network IPs";
            whitelist = {
              reason = "clan mesh network";
              ip = clanMeshIPs;
            };
          }
        ];
        postOverflows.s01Whitelist = [
          (probingWhitelist "nixfiles/matrix-probing-whitelist"
            "matrix clients burst 404s (dead remote media thumbnails, optional endpoints) that http-probing misreads as scanning"
            "matrix API 404 bursts are normal client behavior"
            ".GetMeta('http_hostname') == 'matrix.${flake-self.domains.public}' && .GetMeta('http_path') startsWith '/_matrix/'"
          )
          (probingWhitelist "nixfiles/niks3-probing-whitelist"
            "nix cache clients burst 404s on .narinfo and nar lookups (cache misses) that http-probing misreads as scanning"
            "narinfo/nar 404 bursts are normal binary cache behavior"
            ".GetMeta('http_hostname') == 'niks3.${flake-self.domains.public}' && (.GetMeta('http_path') endsWith '.narinfo' || .GetMeta('http_path') startsWith '/nar/')"
          )
        ];
      };
    };
}

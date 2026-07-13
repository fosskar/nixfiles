{
  # imported by the crowdsec host (gateway), not the matrix host: the ban
  # happens where the netbird-proxy logs are parsed.
  # postoverflow (not parser-stage) whitelist: only defuses http-probing,
  # keeps brute-force detection on /_matrix/client/v3/login intact
  flake.modules.nixos.crowdsecMatrixWhitelist =
    { flake-self, ... }:
    {
      services.crowdsec.localConfig.postOverflows.s01Whitelist = [
        {
          name = "nixfiles/matrix-probing-whitelist";
          description = "matrix clients burst 404s (dead remote media thumbnails, optional endpoints) that http-probing misreads as scanning";
          whitelist = {
            reason = "matrix API 404 bursts are normal client behavior";
            expression = [
              "evt.Overflow.Alert.Scenario == 'crowdsecurity/http-probing' && all(evt.Overflow.Alert.Events, {.GetMeta('http_hostname') == 'matrix.${flake-self.domains.public}' && .GetMeta('http_path') startsWith '/_matrix/'})"
            ];
          };
        }
      ];
    };
}

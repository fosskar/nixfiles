{
  lib,
  python3,
  runCommand,
  writeShellApplication,
}:
let
  # FIXME: drop once NixOS/nixpkgs#575392 lands; urllib3-future socks tests time out (~1.6 h) and
  # fail on hydra, which hid the niquests proxy test failure behind it
  python3' = python3.override {
    self = python3';
    packageOverrides = _: prev: {
      urllib3-future = prev.urllib3-future.overridePythonAttrs { doCheck = false; };
      niquests = prev.niquests.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [ "test_use_proxy_from_environment" ];
      });
    };
  };
  python = python3'.withPackages (packages: [
    packages.caldav
    packages.mcp
  ]);
  contractTest = runCommand "calendar-mcp-contract-test" { nativeBuildInputs = [ python ]; } ''
    CALENDAR_MCP_SOURCE=${./calendar_mcp.py} python ${./test_calendar_mcp.py}
    touch "$out"
  '';
  calendarMcp = writeShellApplication {
    name = "calendar-mcp";
    runtimeInputs = [ python ];
    text = ''
      exec python ${./calendar_mcp.py} "$@"
    '';

    meta = {
      description = "CalDAV MCP server";
      license = lib.licenses.mit;
      mainProgram = "calendar-mcp";
    };
  };
in
calendarMcp.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    tests.contract = contractTest;
  };
})

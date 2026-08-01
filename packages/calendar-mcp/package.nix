{
  lib,
  python3,
  runCommand,
  writeShellApplication,
}:
let
  python = python3.withPackages (packages: [
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

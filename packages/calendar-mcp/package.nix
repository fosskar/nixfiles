{
  lib,
  python3,
  writeShellApplication,
}:
let
  python = python3.withPackages (packages: [
    packages.anyio
    packages.caldav
    packages.mcp
  ]);
in
writeShellApplication {
  name = "calendar-mcp";
  runtimeInputs = [ python ];
  text = ''
    exec python ${./calendar_mcp.py} "$@"
  '';
  meta = {
    description = "CalDAV MCP server for one account";
    license = lib.licenses.mit;
    mainProgram = "calendar-mcp";
  };
}

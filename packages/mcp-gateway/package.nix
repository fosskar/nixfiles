{
  lib,
  python3,
  writeShellApplication,
}:
let
  python = python3.withPackages (packages: [ packages.mcp ]);
in
writeShellApplication {
  name = "mcp-gateway";
  runtimeInputs = [ python ];
  text = ''
    exec python ${./mcp_gateway.py} "$@"
  '';

  meta = {
    description = "MCP gateway for isolated host integrations";
    license = lib.licenses.mit;
    mainProgram = "mcp-gateway";
  };
}

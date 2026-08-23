{
  lib,
  python3,
  runCommand,
  writeShellApplication,
}:
let
  python = python3.withPackages (packages: [ packages.mcp ]);
  contractTest = runCommand "mcp-gateway-contract-test" { nativeBuildInputs = [ python ]; } ''
    MCP_GATEWAY_SOURCE=${./mcp_gateway.py} python ${./test_mcp_gateway.py}
    touch "$out"
  '';
  gateway = writeShellApplication {
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
  };
in
gateway.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    tests.contract = contractTest;
  };
})

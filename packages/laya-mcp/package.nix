{
  lib,
  python3,
  runCommand,
  writeShellApplication,
}:
let
  python = python3.withPackages (packages: [ packages.mcp ]);
  contractTest = runCommand "laya-mcp-contract-test" { nativeBuildInputs = [ python ]; } ''
    LAYA_MCP_SOURCE=${./laya_mcp.py} python ${./test_laya_mcp.py}
    touch "$out"
  '';
  layaMcp = writeShellApplication {
    name = "laya-mcp";
    runtimeInputs = [ python ];
    text = ''
      exec python ${./laya_mcp.py} "$@"
    '';

    meta = {
      description = "laya decision model MCP server";
      license = lib.licenses.mit;
      mainProgram = "laya-mcp";
    };
  };
in
layaMcp.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    tests.contract = contractTest;
  };
})

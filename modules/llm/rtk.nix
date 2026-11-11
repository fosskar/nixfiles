_: {
  flake.modules.homeManager.llm =
    { pkgs, inputs, ... }:
    let
      rtk = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.rtk;

      # generated rather than vendored so the extension always matches the
      # installed rtk; `rtk rewrite` is the single source of truth and the
      # extension is a thin delegator to it
      rtkExtension =
        pkgs.runCommand "rtk-pi-extension"
          {
            nativeBuildInputs = [ rtk ];
          }
          ''
            export HOME="$PWD"
            rtk init -g --agent pi
            install -Dm644 "$HOME/.pi/agent/extensions/rtk.ts" "$out/rtk.ts"
          '';
    in
    {
      home.packages = [ rtk ];

      # pi picks the parser from the resolved store path, so it must end in .ts
      home.file.".pi/agent/extensions/rtk.ts".source = "${rtkExtension}/rtk.ts";
    };
}

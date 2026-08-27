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
            cp "$HOME/.pi/agent/extensions/rtk.ts" "$out"
          '';
    in
    {
      home.packages = [ rtk ];

      home.file = {
        ".pi/agent/extensions/rtk.ts".source = rtkExtension;
        ".omp/agent/extensions/rtk.ts".source = rtkExtension;
      };
    };
}

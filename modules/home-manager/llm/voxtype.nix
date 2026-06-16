{ inputs, ... }:
{
  flake.modules.homeManager.voxtype =
    { pkgs, ... }:
    {
      services.voxtype = {
        enable = true;
        package = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.parakeet-migraphx;
        loadModels = [
          "parakeet-unified-en-0.6b"
          "parakeet-tdt-0.6b-v3"
        ];
        settings = {
          engine = "parakeet";

          audio.max_duration_secs = 300;

          hotkey = {
            enabled = false;
            mode = "toggle";
          };

          osd.enabled = false;

          output = {
            mode = "type";
            fallback_to_clipboard = true;
            notification.on_transcription = false;
          };

          text = {
            spoken_punctuation = true;
            replacements = {
              "vox type" = "Voxtype";
              "nick sauce" = "NixOS";
              "nicks" = "nix";
              "mixed graphs" = "MIGraphX";
              "pie chat" = "pi-chat";
              "near eye" = "niri";
            };
          };

          parakeet = {
            model = "parakeet-tdt-0.6b-v3";
            streaming = false;
          };
          vad = {
            enabled = true;
            backend = "energy";
          };
        };
      };
    };
}

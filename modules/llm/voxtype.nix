{ inputs, ... }:
{
  flake.modules.homeManager.voxtype =
    { lib, pkgs, ... }:
    let
      # symlink, not copy: encoder-model.onnx loads its 2.4 GB .data sibling by
      # relative name, so the files must share a directory
      fetchParakeetModel =
        name: files:
        pkgs.runCommand name { } (
          ''
            mkdir -p "$out"
          ''
          + lib.concatStrings (
            lib.mapAttrsToList (file: hash: ''
              ln -s ${
                pkgs.fetchurl {
                  url = "https://models.voxtype.io/parakeet/${name}/${file}";
                  inherit hash;
                }
              } "$out/${file}"
            '') files
          )
        );

      parakeetModel = fetchParakeetModel "parakeet-tdt-0.6b-v3" {
        "config.json" = "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=";
        "decoder_joint-model.onnx" = "sha256-6Xjd9miFJxgsEP3i60uDBoQhZImF7yP3qGvnMr6HBsE=";
        "encoder-model.onnx" = "sha256-mKdLIbTMABfB5wMDGaSpb0qVBuUPBwjzpRbQKnfJa7E=";
        "encoder-model.onnx.data" = "sha256-miLTcsUUVcNPE0BdolILrvtxJb0WmBOXVhQj7TLSTzY=";
        "vocab.txt" = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
      };
      # english-only, but the only model that can do cache-aware streaming.
      # needs streaming = true, the streaming_* values below, hotkey mode
      # "toggle", and a running dotoold, else every partial pays ~700ms of
      # uinput setup and synthetic keys leak into the focused window
      # parakeetModel = fetchParakeetModel "parakeet-unified-en-0.6b" {
      #   "decoder_joint.onnx" = "sha256-ZGSMkZNepIGenDHqiiDwEdOxyWC+OGHLi8dN8CWc2Zg=";
      #   "encoder.onnx" = "sha256-UAg90LKvUDuH6o/Pn9fX3BXdoxMOQRMBfIs37QBBi6Q=";
      #   "encoder.onnx.data" = "sha256-wFSyky7hOqOe2EmCo5mCLzGTMR+2/Y4eIEVmciYUvYc=";
      #   "tokenizer.model" = "sha256-B9TlpjhApTqy1NEG0odHaBQ/s/vdR5OLORDS2gW/sKk=";
      #   "vocab.txt" = "sha256-rmHJt0PLR8BM5vsTBEQhBkbtD0DJU8d+4YVRhZYK+U8=";
      # };
    in
    {
      services.voxtype = {
        enable = true;
        package = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.parakeet-migraphx;
        settings = {
          engine = "parakeet";

          audio.max_duration_secs = 300;

          hotkey = {
            enabled = true;
            mode = "push_to_talk";
            key = "RIGHTCTRL";
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
            model = toString parakeetModel;
            streaming = false;
            # voxtype's own streaming defaults (1.5/0.5/0.5) map to mel-frame
            # counts not divisible by 8, which parakeet-rs 0.3.5 rejects at
            # startup; these are the crate's blessed values (560/56/56 frames)
            # streaming_chunk_secs = 0.56;
            # streaming_left_context_secs = 5.6;
            # streaming_right_context_secs = 0.56;
          };
          vad = {
            enabled = true;
            backend = "energy";
            threshold = 0.4;
          };
        };
      };
    };
}

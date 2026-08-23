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

      # english-only. v3 is newer but multilingual, and its per-utterance
      # language detection turns short english clips into cyrillic ("submit"
      # -> "Сабмит"), which also breaks smart_auto_submit. v2 has no other
      # language in its vocab, and beats v3 on 6 of 8 english wer benchmarks
      parakeetModel = fetchParakeetModel "parakeet-tdt-0.6b-v2" {
        "config.json" = "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=";
        "decoder_joint-model.onnx" = "sha256-y7UqB71wq1tn+EOdSzzYcEsYRntEMLysta2r4VS40ZE=";
        "encoder-model.onnx" = "sha256-OYe80oF12CnRKIiplqhOj2Kg43TZ/9ZAZiwVFa3GedM=";
        "encoder-model.onnx.data" = "sha256-TatzYtSHTYWWUEWx5BstYd0swPslZxp/az3Ee/EgzEE=";
        "vocab.txt" = "sha256-7BgrcN1CETr/bFNyx1ysWMlSRD6yIyL1e71/U5d9SX0=";
      };
      # multilingual (25 european languages); needed for german dictation
      # parakeetModel = fetchParakeetModel "parakeet-tdt-0.6b-v3" {
      #   "config.json" = "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=";
      #   "decoder_joint-model.onnx" = "sha256-6Xjd9miFJxgsEP3i60uDBoQhZImF7yP3qGvnMr6HBsE=";
      #   "encoder-model.onnx" = "sha256-mKdLIbTMABfB5wMDGaSpb0qVBuUPBwjzpRbQKnfJa7E=";
      #   "encoder-model.onnx.data" = "sha256-miLTcsUUVcNPE0BdolILrvtxJb0WmBOXVhQj7TLSTzY=";
      #   "vocab.txt" = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
      # };
      # english-only, but the only model that can do cache-aware streaming. its
      # file names (encoder.onnx, tokenizer.model) are for the ParakeetUnified
      # loader; the batch TDT loader below cannot read this layout. streaming
      # also forces hotkey mode "toggle" and bypasses smart_auto_submit
      # parakeetModel = fetchParakeetModel "parakeet-unified-en-0.6b" {
      #   "decoder_joint.onnx" = "sha256-ZGSMkZNepIGenDHqiiDwEdOxyWC+OGHLi8dN8CWc2Zg=";
      #   "encoder.onnx" = "sha256-UAg90LKvUDuH6o/Pn9fX3BXdoxMOQRMBfIs37QBBi6Q=";
      #   "encoder.onnx.data" = "sha256-wFSyky7hOqOe2EmCo5mCLzGTMR+2/Y4eIEVmciYUvYc=";
      #   "tokenizer.model" = "sha256-B9TlpjhApTqy1NEG0odHaBQ/s/vdR5OLORDS2gW/sKk=";
      #   "vocab.txt" = "sha256-rmHJt0PLR8BM5vsTBEQhBkbtD0DJU8d+4YVRhZYK+U8=";
      # };
    in
    {
      # the home-manager module binds voxtype to default.target, so it starts
      # before niri imports WAYLAND_DISPLAY into the user manager. wtype then
      # cannot connect and output falls back to dotool, which types us keycodes
      # into the de layout (y/z swapped, ' becomes ä)
      systemd.user.services.voxtype = {
        Unit = {
          PartOf = lib.mkForce [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
      };

      services.voxtype = {
        enable = true;
        package = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.parakeet-migraphx;
        settings = {
          engine = "parakeet";

          audio.max_duration_secs = 300;

          hotkey = {
            enabled = true;
            mode = "toggle";
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
            # say "submit" at the end to press enter; the word is stripped.
            # only works in batch mode: the streaming path never calls
            # detect_submit
            smart_auto_submit = true;
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

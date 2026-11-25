{ self, ... }:
{
  # hold alt+shift+space -> hex transcript -> pi with a soul and bash -> kokoro speaks the reply
  flake.modules.homeManager.voiceAssistant =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hex = lib.getExe config.programs.hex.package;
      kokoroRepo = "https://huggingface.co/hexgrad/Kokoro-82M/resolve/f3ff3571791e39611d31c381e3a41a3af07b4987";
      kokoroConfig = pkgs.fetchurl {
        url = "${kokoroRepo}/config.json";
        hash = "sha256-WrsB4kA7ByvwPQT94WBEPiCdeg2tSaQjvhUZa5tDwX8=";
      };
      kokoroWeights = pkgs.fetchurl {
        url = "${kokoroRepo}/kokoro-v1_0.pth";
        hash = "sha256-SW26EY0aWPXz2y78iNvcIW4Eg/yJ/m5H7h8sU/GK0eQ=";
      };
      kokoroVoice = pkgs.fetchurl {
        url = "${kokoroRepo}/voices/am_michael.pt";
        hash = "sha256-mkQ7eaSyJImlsKt8ZRoLzRowvvZ1woMz8Glxq71HvTc=";
      };

      # loading torch and the model takes ~4 s, so one resident process serves every reply:
      # a client writes text, half-closes, and reads 24 kHz s16 mono pcm until the server closes
      kokoroServer =
        pkgs.writers.writePython3Bin "kokoro-tts"
          {
            libraries = [
              pkgs.python3Packages.kokoro
              # misaki's english g2p runs `spacy.cli.download` when this model is missing
              pkgs.python3Packages.spacy-models.en_core_web_sm
            ];
            flakeIgnore = [
              "E402"
              "E501"
            ];
          }
          ''
            import os
            import socket

            # bind before importing torch and loading the model so early clients wait in the backlog
            path = os.path.join(os.environ["XDG_RUNTIME_DIR"], "kokoro-tts.sock")
            if os.path.exists(path):
                os.unlink(path)
            server = socket.socket(socket.AF_UNIX)
            server.bind(path)
            server.listen()

            import numpy as np
            from kokoro import KModel, KPipeline

            repo = "hexgrad/Kokoro-82M"
            model = KModel(repo_id=repo, config="${kokoroConfig}", model="${kokoroWeights}").eval()
            pipeline = KPipeline(lang_code="a", repo_id=repo, model=model)

            while True:
                conn, _ = server.accept()
                with conn:
                    text = b""
                    while chunk := conn.recv(65536):
                        text += chunk
                    try:
                        for result in pipeline(text.decode(), voice="${kokoroVoice}"):
                            pcm = (result.audio.numpy() * 32767).clip(-32768, 32767).astype(np.int16)
                            conn.sendall(pcm.tobytes())
                    # a new key press stopped the reply mid-sentence
                    except (BrokenPipeError, ConnectionResetError):
                        pass
          '';

      # replaces pi's coding prompt; appended, haiku kept answering in markdown lists
      systemPrompt = pkgs.writeText "voice-assistant-prompt.md" ''
        ${builtins.readFile self.llm.souls.rocky}

        ## voice assistant

        You run on simon's desktop (NixOS, umbriel compositor, noctalia shell) and act on it with the bash tool.
        His words come from speech-to-text and may be misheard; ask when a request is unclear.

        - replies are read aloud: plain sentences, no markdown, lists, code, paths, or urls; one to three short sentences
        - start gui apps with `umbriel msg spawn <cmd>` or `focus-or-spawn <app-id> <cmd>`, never as a child of bash
        - volume: `wpctl`; media: `playerctl`; shell panels: `noctalia msg`
        - before anything that deletes, overwrites, installs, sends, buys, or shuts down, say what you will run and wait for a yes in his next message
      '';

      reply = pkgs.writeShellApplication {
        name = "voice-assistant-reply";
        runtimeInputs = [
          config.programs.pi-coding-agent.package
          pkgs.socat
          pkgs.pipewire
        ];
        text = ''
          sessions="''${XDG_STATE_HOME:-$HOME/.local/state}/voice-assistant"
          mkdir -p "$sessions"
          # one conversation until 10 minutes of silence
          continue=()
          if [ -n "$(find "$sessions" -name '*.jsonl' -mmin -10 -print -quit)" ]; then
            continue=(--continue)
          fi

          # the agent's bash needs the user's tools; systemd-run starts with the manager's PATH
          export PATH="$PATH:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin"
          cd "$HOME"
          answer=$(pi -p "''${continue[@]}" \
            --session-dir "$sessions" \
            --model anthropic/claude-haiku-5-5 --thinking off \
            --no-extensions --no-context-files --no-prompt-templates --no-mcp --no-themes --no-skills \
            --system-prompt ${systemPrompt} \
            -- "$1")

          printf '%s\n' "$answer" \
            | socat -t 120 - "UNIX-CONNECT:$XDG_RUNTIME_DIR/kokoro-tts.sock" \
            | pw-play --rate 24000 --channels 1 --format s16 -
        '';
      };

      listen = pkgs.writeShellApplication {
        name = "voice-assistant-listen";
        text = ''
          # a new press interrupts the reply still thinking or speaking
          if systemctl --user is-active --quiet voice-assistant-reply.service; then
            systemctl --user stop voice-assistant-reply.service
          fi
          exec ${hex} dictation start
        '';
      };

      send = pkgs.writeShellApplication {
        name = "voice-assistant-send";
        text = ''
          status=0
          request=$(${hex} dictation stop --print) || status=$?
          # 4: hex heard no speech
          if [ "$status" -eq 4 ]; then
            exit 0
          fi
          if [ "$status" -ne 0 ]; then
            exit "$status"
          fi
          # the agent's bash reaches the compositor through these; the unit does not inherit them
          exec systemd-run --user --collect --quiet --unit voice-assistant-reply \
            -E WAYLAND_DISPLAY -E UMBRIEL_SOCKET \
            ${lib.getExe reply} "$request"
        '';
      };
    in
    {
      systemd.user.services.kokoro-tts = {
        Unit.Description = "Kokoro text-to-speech for the voice assistant";
        Service = {
          ExecStart = lib.getExe kokoroServer;
          # weights come from the store; never fetch from hugging face at runtime
          Environment = [ "HF_HUB_OFFLINE=1" ];
          Restart = "on-failure";
        };
        Install.WantedBy = [ "default.target" ];
      };

      # `--print` returns the transcript instead of pasting it
      programs.umbriel.settings.keybinds."Alt+Shift+Space" = {
        action = "spawn ${lib.getExe listen}";
        release = "spawn ${lib.getExe send}";
        repeat = false;
      };
    };
}

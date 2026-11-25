{ self, ... }:
{
  # hold alt+shift+space -> hex transcript -> pi with a soul and bash -> piper speaks the reply
  flake.modules.homeManager.voiceAssistant =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hex = lib.getExe config.programs.hex.package;
      voice = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/ryan/high/en_US-ryan-high";
      # piper ignores `-c` and loads `<model>.json` next to the model
      piperVoice = pkgs.linkFarm "piper-voice-en_US-ryan-high" {
        "voice.onnx" = pkgs.fetchurl {
          url = "${voice}.onnx";
          hash = "sha256-s5kNdgbhg+yNv7pwpGBwdPFi3hoMQS4BgNH/YLsVTso=";
        };
        "voice.onnx.json" = pkgs.fetchurl {
          url = "${voice}.onnx.json";
          hash = "sha256-xtO5jwgxXLS+vw1J1Q/E/0kbUDxkuUDNPVyihUO0gBE=";
        };
      };

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
          pkgs.piper-tts
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
            | piper -m ${piperVoice}/voice.onnx --output-raw \
            | pw-play --rate 22050 --channels 1 --format s16 -
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
          # the user manager lacks the session's wayland and umbriel sockets
          exec systemd-run --user --collect --quiet --unit voice-assistant-reply \
            -E WAYLAND_DISPLAY -E UMBRIEL_SOCKET \
            ${lib.getExe reply} "$request"
        '';
      };
    in
    {
      # `--print` returns the transcript instead of pasting it
      programs.umbriel.settings.keybinds."Alt+Shift+Space" = {
        action = "spawn ${lib.getExe listen}";
        release = "spawn ${lib.getExe send}";
        repeat = false;
      };
    };
}

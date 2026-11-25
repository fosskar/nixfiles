{ self, ... }:
{
  # alt+shift+space toggles listening; mic -> whisper -> openrouter llm with a
  # shell tool -> kokoro, with turn detection and interruption from pipecat
  flake.modules.homeManager.voiceAssistant =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      whisperRepo = "https://huggingface.co/Systran/faster-whisper-base.en/resolve/3d3d5dee26484f91867d81cb899cfcf72b96be6c";
      # base.en transcribes a 4 s sentence in 0.4 s on cpu; small.en took 1.2 s
      whisperModel = pkgs.linkFarm "faster-whisper-base.en" {
        "config.json" = pkgs.fetchurl {
          url = "${whisperRepo}/config.json";
          hash = "sha256-87w4Ien8dqJ7rlOOEa5bZ33N01K0YAQpznlR05hWmus=";
        };
        "model.bin" = pkgs.fetchurl {
          url = "${whisperRepo}/model.bin";
          hash = "sha256-KhZpJVOaFgBfFP8yg1n5ua253E+2Mbs7InUmhi6T4u8=";
        };
        "tokenizer.json" = pkgs.fetchurl {
          url = "${whisperRepo}/tokenizer.json";
          hash = "sha256-kpxSUkCUNtzhs4p10au8teEy0XDY4yTk4E7ZFfotIt8=";
        };
        "vocabulary.txt" = pkgs.fetchurl {
          url = "${whisperRepo}/vocabulary.txt";
          hash = "sha256-/3dYh0bTolldMqtbaf/XuVziRBrFdTPLZvw+tXWhFc8=";
        };
      };

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

      systemPrompt = pkgs.writeText "voice-assistant-prompt.md" ''
        ${builtins.readFile self.llm.souls.rocky}

        ## voice assistant

        You run on simon's desktop (NixOS, umbriel compositor, noctalia shell) and act on it with the run_shell tool.
        His words come from speech-to-text and may be misheard; ask when a request is unclear.

        - replies are read aloud: plain sentences, no markdown, lists, code, paths, or urls; one to three short sentences
        - start gui apps with `umbriel msg spawn <cmd>` or `focus-or-spawn <app-id> <cmd>`, never as a child of the shell
        - volume: `wpctl`; media: `playerctl`; shell panels: `noctalia msg`
        - before anything that deletes, overwrites, installs, sends, buys, or shuts down, say what you will run and wait for a yes in his next message
      '';

      start = pkgs.writeShellApplication {
        name = "voice-assistant-start";
        runtimeInputs = [ config.programs.pi-coding-agent.package ];
        text = ''
          # pi holds the openrouter login; no separate secret
          OPENROUTER_API_KEY=$(pi auth print-bearer-token --provider openrouter)
          export OPENROUTER_API_KEY
          # the shell tool needs the user's tools; the unit starts with the manager's PATH
          export PATH="$PATH:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin"
          exec ${lib.getExe pkgs.local.voice-assistant}
        '';
      };
    in
    {
      systemd.user.services.voice-assistant = {
        Unit = {
          Description = "Voice assistant";
          # the shell tool reaches the compositor through the session's environment
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = lib.getExe start;
          Environment = [
            "VOICE_ASSISTANT_PROMPT=${systemPrompt}"
            "VOICE_ASSISTANT_MODEL=anthropic/claude-haiku-5.5"
            "WHISPER_MODEL=${whisperModel}"
            "KOKORO_CONFIG=${kokoroConfig}"
            "KOKORO_WEIGHTS=${kokoroWeights}"
            "KOKORO_VOICE=${kokoroVoice}"
            # models come from the store; never fetch from hugging face at runtime
            "HF_HUB_OFFLINE=1"
          ];
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # the process starts deaf; SIGUSR1 toggles listening
      programs.umbriel.settings.keybinds."Alt+Shift+Space" = {
        action = "spawn systemctl --user kill --kill-whom=main --signal=SIGUSR1 voice-assistant.service";
        repeat = false;
      };
    };
}

{ self, ... }:
{
  # alt+shift+space toggles listening; mic -> speech-to-speech model on openrouter
  # with a shell tool -> headset, with turn detection and interruption from pipecat
  flake.modules.homeManager.voiceAssistant =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      systemPrompt = pkgs.writeText "voice-assistant-prompt.md" ''
        ${builtins.readFile self.llm.souls.rocky}

        ## voice assistant

        You run on simon's desktop (NixOS, umbriel compositor, noctalia shell) and act on it with the run_shell tool.
        You hear him directly and answer in speech. Speak fast and lively, like someone excited to help.

        - one to three short sentences; no lists, code, paths, or urls
        - when a request needs a command, call run_shell at once and say nothing first; speak only after you have the result
        - start gui apps with `umbriel msg spawn <cmd>` or `focus-or-spawn <app-id> <cmd>`, never as a child of the shell
        - volume: `wpctl`; media: `playerctl`; shell panels: `noctalia msg`
        - before anything that deletes, overwrites, installs, sends, buys, or shuts down, say what you will run and wait for a yes in his next message
        - when you did not understand the audio, say so and ask again
      '';

      start = pkgs.writeShellApplication {
        name = "voice-assistant-start";
        runtimeInputs = [ config.programs.pi-coding-agent.package ];
        text = ''
          # the toggle key sends SIGUSR1, which kills a process that has no handler
          # yet; an ignored signal stays ignored across exec until python installs one
          trap "" USR1
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
            # 1.3 s to first sound; the full gpt-audio took 1.5 s and cost 15x more
            "VOICE_ASSISTANT_MODEL=openai/gpt-audio-mini"
            "VOICE_ASSISTANT_VOICE=ash"
          ];
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # the process starts deaf; SIGUSR1 toggles listening, with a beep either way
      programs.umbriel.settings.keybinds."Alt+Shift+Space" = {
        action = "spawn systemctl --user kill --kill-whom=main --signal=SIGUSR1 voice-assistant.service";
        repeat = false;
      };
    };
}

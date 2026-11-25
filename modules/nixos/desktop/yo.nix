{ inputs, ... }:
{
  # voice commands: hold alt+shift+space -> hex transcript -> yo's sentence matcher -> yo.scripts
  flake.modules.nixos.yo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      focus-or-spawn = lib.getExe pkgs.local.focus-or-spawn;
      umbriel = "${config.programs.umbriel.package}/bin/umbriel";
      wpctl = "${pkgs.wireplumber}/bin/wpctl";
    in
    {
      imports = [ inputs.yo.nixosModules.yo ];

      # `yo say` plays locally through `piper` and `aplay` from PATH; the yo module installs neither
      environment.systemPackages = [
        pkgs.piper-tts
        pkgs.alsa-utils
      ];
      # `yo say` warns unless ~/.config/yo/clients.json exists; yo-rs only writes it on disconnect
      systemd.user.tmpfiles.rules = [ "f %h/.config/yo/clients.json 0644 - - - []" ];

      # the module's default reads the renamed `pkgs.system`; the yo-rs server stays off
      services.yo-rs.package = inputs.yo.packages.${pkgs.stdenv.hostPlatform.system}.yo-rs;

      # yo waits for each script's stdout to close, so gui apps go through
      # umbriel's spawn instead of being children of the script
      yo.scripts = {
        open = {
          description = "Open an application or website";
          parameters = [
            {
              name = "app";
              type = "string";
              description = "Application or website to open";
            }
          ];
          voice.sentences = [ "(open|start|launch) [the|my] {app}" ];
          voice.lists.app.values = [
            {
              "in" = "zen|browser|zen browser";
              out = "zen";
            }
            {
              "in" = "terminal|ghostty";
              out = "terminal";
            }
            {
              "in" = "discord|webcord";
              out = "webcord";
            }
            {
              "in" = "element|matrix";
              out = "element";
            }
            {
              "in" = "youtube";
              out = "youtube";
            }
          ];
          code = ''
            case "$app" in
              zen) exec ${focus-or-spawn} zen-beta zen-beta ;;
              terminal) exec ${umbriel} msg spawn ghostty ;;
              webcord) exec ${focus-or-spawn} WebCord webcord ;;
              element) exec ${focus-or-spawn} Element element-desktop ;;
              youtube) exec ${umbriel} msg spawn xdg-open https://www.youtube.com ;;
            esac
          '';
        };

        volume = {
          description = "Change the output volume";
          parameters = [
            {
              name = "direction";
              type = "string";
              description = "up or down";
            }
          ];
          voice.sentences = [
            "[turn] [the] volume {direction}"
            "make it {direction}"
          ];
          voice.lists.direction.values = [
            {
              "in" = "up|louder";
              out = "up";
            }
            {
              "in" = "down|quieter";
              out = "down";
            }
          ];
          code = ''
            case "$direction" in
              up) exec ${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 10%+ ;;
              down) exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 10%- ;;
            esac
          '';
        };

        workspace = {
          description = "Switch to a workspace";
          parameters = [
            {
              name = "number";
              type = "int";
              description = "Workspace position";
            }
          ];
          # yo splits sentences on spaces before expanding groups, so a group
          # alternative must be one word
          voice.sentences = [
            "go to workspace {number}"
            "(switch|show) [to] workspace {number}"
          ];
          voice.lists.number.values =
            lib.imap1
              (n: word: {
                "in" = "${toString n}|${word}";
                out = toString n;
              })
              [
                "one"
                "two"
                "three"
                "four"
                "five"
                "six"
                "seven"
                "eight"
                "nine"
              ];
          code = ''
            exec ${umbriel} msg workspace-switch "$number"
          '';
        };

        time = {
          description = "Say the current time";
          voice = {
            speak = true;
            sentences = [
              "what time is it"
              "what is the time"
              "tell me the time"
              "say the time"
            ];
          };
          code = ''
            echo "It is $(date +%H:%M)"
          '';
        };
      };
    };

  flake.modules.homeManager.yo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hex = lib.getExe config.programs.hex.package;
      yo-hex = pkgs.writeShellApplication {
        name = "yo-hex";
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
          exec yo "do" "$request"
        '';
      };
    in
    {
      # hold to record a command; `--print` returns the transcript instead of pasting it
      programs.umbriel.settings.keybinds."Alt+Shift+Space" = {
        action = "spawn ${hex} dictation start";
        release = "spawn ${lib.getExe yo-hex}";
        repeat = false;
      };
    };
}

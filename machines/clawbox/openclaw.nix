{
  config,
  pkgs,
  ...
}:
let
  stateDir = "/root/.openclaw";
in
{
  environment.systemPackages = with pkgs; [
    llm-agents.openclaw
    llm-agents.agent-browser
    llm-agents.claude-code
    llm-agents.codex
    llm-agents.opencode
    whisper-cpp
    gh
    # libreoffice  # disabled: noto-fonts-subset build failure
    ffmpeg
    imagemagick
    tesseract
    bun
    newsboat
    ripgrep
    sqlite
    zip
    unzip
  ];

  clan.core.vars.generators.openclaw = {
    prompts = {
      brave-api-key = {
        description = "Brave Search API key (get free at brave.com/search/api)";
        type = "hidden";
        persist = true;
      };
      elevenlabs-api-key = {
        description = "ElevenLabs API key for TTS";
        type = "hidden";
        persist = true;
      };
      discord-bot-token = {
        description = "Discord bot token";
        type = "hidden";
        persist = true;
      };
      openrouter-api-key = {
        description = "OpenRouter API key for AI";
        type = "hidden";
        persist = true;
      };
    };
    files."env".secret = true;
    script = ''
      {
        echo "BRAVE_API_KEY=$(cat $prompts/brave-api-key)"
        echo "ELEVENLABS_API_KEY=$(cat $prompts/elevenlabs-api-key)"
        echo "DISCORD_BOT_TOKEN=$(cat $prompts/discord-bot-token)"
        echo "OPENROUTER_API_KEY=$(cat $prompts/openrouter-api-key)"
      } > $out/env
    '';
  };

  environment.sessionVariables = {
    OPENCLAW_DISABLE_BONJOUR = "1";
    WHISPER_CPP_MODEL = "${stateDir}/ggml-base.bin";
    OPENCLAW_NIX_MODE = "1";
  };

  environment.shellInit = ''
    [ -f "${config.clan.core.vars.generators.openclaw.files."env".path}" ] && . "${
      config.clan.core.vars.generators.openclaw.files."env".path
    }"
  '';

  systemd.services.openclaw = {
    description = "openclaw AI gateway";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    path = config.environment.systemPackages;
    environment = {
      OPENCLAW_DISABLE_BONJOUR = "1";
      WHISPER_CPP_MODEL = "${stateDir}/ggml-base.bin";
      OPENCLAW_NIX_MODE = "1";
      # workaround: openclaw 2026.2.26 rejects hardlinked plugin manifests (nix store dedup)
      OPENCLAW_BUNDLED_PLUGINS_DIR = "${stateDir}/bundled-extensions";
    };
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = stateDir;
      EnvironmentFile = config.clan.core.vars.generators.openclaw.files."env".path;
      ExecStartPre = [
        # copy bundled extensions to mutable dir (breaks nix store hardlinks that openclaw rejects)
        "${pkgs.bash}/bin/bash -c 'rm -rf ${stateDir}/bundled-extensions && cp -r --no-preserve=links ${pkgs.llm-agents.openclaw}/lib/openclaw/extensions ${stateDir}/bundled-extensions'"
        "${pkgs.coreutils}/bin/mkdir -p ${stateDir}"
      ];
      ExecStart = "${pkgs.llm-agents.openclaw}/bin/openclaw gateway";
      Restart = "always";
      RestartSec = "10s";
      MemoryMax = "12G";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts.":443".extraConfig = ''
      tls internal { on_demand }
      reverse_proxy 127.0.0.1:18789
    '';
    globalConfig = ''
      local_certs
      skip_install_trust
    '';
  };

  networking.firewall.allowedTCPPorts = [ 443 ];
}

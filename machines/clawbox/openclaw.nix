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
    signal-cli
    whisper-cpp
    gh
    libreoffice
    ffmpeg
    imagemagick
    tesseract
    bun
    ripgrep
    zip
    unzip
    (python3.withPackages (ps: [ ps.python-pptx ]))
  ];

  clan.core.vars.generators.openclaw = {
    prompts.brave-api-key = {
      description = "Brave Search API key (get free at brave.com/search/api)";
      type = "hidden";
      persist = true;
    };
    prompts.elevenlabs-api-key = {
      description = "ElevenLabs API key for TTS";
      type = "hidden";
      persist = true;
    };
    files."env".secret = true;
    script = ''
      {
        echo "BRAVE_API_KEY=$(cat $prompts/brave-api-key)"
        echo "ELEVENLABS_API_KEY=$(cat $prompts/elevenlabs-api-key)"
      } > $out/env
    '';
  };

  environment.sessionVariables = {
    OPENCLAW_DISABLE_BONJOUR = "1";
    WHISPER_CPP_MODEL = "${stateDir}/ggml-base.bin";
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
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = stateDir;
      EnvironmentFile = config.clan.core.vars.generators.openclaw.files."env".path;
      Environment = [
        "OPENCLAW_DISABLE_BONJOUR=1"
        "WHISPER_CPP_MODEL=${stateDir}/ggml-base.bin"
      ];
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p ${stateDir}"
      ];
      ExecStart = "${pkgs.llm-agents.openclaw}/bin/openclaw gateway";
      Restart = "always";
      RestartSec = "10s";
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

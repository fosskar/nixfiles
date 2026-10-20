{
  # text-to-speech and speech-to-text for the home assistant assist pipeline
  flake.modules.nixos.wyomingPiper =
    { config, flake-self, ... }:
    let
      piperPort = 10200;
      whisperPort = 10300;
      host = flake-self.hosts.${config.networking.hostName}.lan;
    in
    {
      services.wyoming.piper.servers.default = {
        enable = true;
        voice = "en_US-ryan-high";
        uri = "tcp://0.0.0.0:${toString piperPort}";
        useCUDA = false;
        zeroconf.enable = false;
      };

      # language "en" with the auto stt library and model picks a sherpa parakeet model
      services.wyoming.faster-whisper.servers.default = {
        enable = true;
        language = "en";
        uri = "tcp://0.0.0.0:${toString whisperPort}";
        zeroconf.enable = false;
      };

      # home assistant on ha-green connects from the lan network
      networking.firewall.allowedTCPPorts = [
        piperPort
        whisperPort
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Wyoming Piper";
          url = "tcp://${host}:${toString piperPort}";
          conditions = [ "[CONNECTED] == true" ];
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
        }
        {
          name = "Wyoming Whisper";
          url = "tcp://${host}:${toString whisperPort}";
          conditions = [ "[CONNECTED] == true" ];
          enabled = true;
          alerts = [ { type = "matrix"; } ];
          interval = "5m";
        }
      ];
    };
}

_: {
  flake.modules.nixos.hermesSignal =
    { self, ... }:
    {
      imports = [ self.modules.nixos.signalCli ];

      services.hermes-agent.environment = {
        # signal-cli.nix binds its http daemon to this loopback address
        SIGNAL_HTTP_URL = "http://127.0.0.1:18081";
        SIGNAL_ALLOW_ALL_USERS = "false";
      };
    };
}

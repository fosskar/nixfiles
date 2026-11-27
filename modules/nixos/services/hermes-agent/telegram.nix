_: {
  flake.modules.nixos.hermesTelegram = _: {
    # python-telegram-bot lives in the messaging group, outside the default package
    services.hermes-agent.extraDependencyGroups = [ "messaging" ];
  };
}

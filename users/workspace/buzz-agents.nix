{
  inputs,
  osConfig,
  ...
}:
{
  imports = [ inputs.buzz-flake.homeModules.buzz-agents ];

  services.buzz-agents = {
    enable = true;
    relayUrl = "wss://buzz.fosskar.eu";
    openrouterEnvironmentFile =
      osConfig.clan.core.vars.generators.workspace-openrouter.files."openrouter.env".path;

    agents.orouter = {
      displayName = "ORouter";
      model = "deepseek/deepseek-v4-flash-0731";
      systemPrompt = "test agent";
      privateKeyFile = osConfig.clan.core.vars.generators.workspace-buzz-orouter.files."agent.env".path;
      respondTo = "anyone";
    };
  };
}

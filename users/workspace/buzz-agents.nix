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
    # DMs are always owner-gated in buzz-acp (author_allowed); without this
    # every direct message is dropped. respondTo still governs channels
    ownerPubkey = "1c9f5bb1b4adb233b8c383c1ee98cf40a90d6194d63bee11e6d332955836e6a2";
    openrouterEnvironmentFile =
      osConfig.clan.core.vars.generators.workspace-openrouter.files."openrouter.env".path;

    agents.orouter = {
      displayName = "Oro";
      model = "z-ai/glm-5.3-flash";
      systemPrompt = "test agent";
      privateKeyFile = osConfig.clan.core.vars.generators.workspace-buzz-orouter.files."agent.env".path;
      respondTo = "anyone";
    };
  };
}

{
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.noctalia-plugins.nixosModules.nostr-chat ];

  clan.core.vars.generators.nostr-chat = {
    share = true;
    prompts.nsec.description = "nostr private key (nsec or hex)";
    files."nsec" = {
      owner = "simon";
      group = "users";
    };
    script = ''cp "$prompts/nsec" "$out/nsec"'';
  };

  services.nostr-chat = {
    peerPubkey = "0fa77e8daf14b2007acdf8d65180792321b45504c8c9ec1a59f04ea8a9b3dde1";
    relays = [ "wss://nostr.fosskar.eu" ];
    displayName = "dexter";
    secretCommand = "cat ${config.clan.core.vars.generators.nostr-chat.files."nsec".path}";
  };
}

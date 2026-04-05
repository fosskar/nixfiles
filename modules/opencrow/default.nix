{
  inputs,
  pkgs,
  config,
  mylib,
  ...
}:
{
  imports = [
    inputs.opencrow.nixosModules.default
  ]
  ++ mylib.scanPaths ./. { exclude = [ "skills" ]; };

  clan.core.vars.generators.opencrow = {
    files.nostr-private-key.secret = true;
    files.nostr-public-key.secret = false;

    runtimeInputs = with pkgs; [ nak ];

    script = ''
      sk=$(nak key generate)
      pk=$(nak key public "$sk")
      echo -n "$sk" > "$out/nostr-private-key"
      echo -n "$pk" > "$out/nostr-public-key"
    '';
  };

  users.groups.opencrow.gid = 2000;

  containers.opencrow.config = {
    users = {
      users.opencrow.uid = 2000;
      groups.opencrow.gid = 2000;
    };
  };

  containers.opencrow.config.systemd.tmpfiles.rules = [
    "d /var/lib/opencrow/.config 0750 opencrow opencrow -"
  ];

  services.opencrow = {
    enable = true;

    piPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

    skills.web = "${config.services.opencrow.package}/share/opencrow/skills/web";

    extensions = {
      memory = true;
      reminders = true;
    };

    environment = {
      TZ = "Europe/Berlin";

      OPENCROW_BACKEND = "nostr";
      OPENCROW_NOSTR_RELAYS = "wss://nos.lol,wss://relay.damus.io";
      OPENCROW_NOSTR_DM_RELAYS = "wss://nos.lol,wss://relay.damus.io,wss://relay.0xchat.com";
      OPENCROW_NOSTR_PRIVATE_KEY_FILE = "%d/nostr-private-key";
      OPENCROW_NOSTR_ALLOWED_USERS = "npub16le4pxhfvy04jwcp9rhw3ustkwt7sm0jydgq4lr3qderycrlm8ysjxmufc";

      OPENCROW_NOSTR_NAME = "crow";
      OPENCROW_NOSTR_DISPLAY_NAME = "crow";
      OPENCROW_NOSTR_ABOUT = "henlo";
      #OPENCROW_NOSTR_PICTURE = "";

      OPENCROW_PI_PROVIDER = "anthropic";
      OPENCROW_PI_MODEL = "claude-sonnet-4-6";

      OPENCROW_SOUL_FILE = "${./soul.md}";
    };

    extraPackages = with pkgs; [
      coreutils
      curl
      fd
      file
      git
      hurl
      jq
      less
      openssh
      ripgrep
      tree
      unzip
      python3
      w3m
      wget
      yq-go
      zip
    ];

    credentialFiles."nostr-private-key" =
      config.clan.core.vars.generators.opencrow.files.nostr-private-key.path;
  };
}

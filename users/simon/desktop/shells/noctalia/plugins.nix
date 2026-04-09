_: {

  programs.noctalia-shell = {
    plugins = {
      sources = [
        {
          enabled = true;
          name = "Official Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
        {
          enabled = true;
          name = "Mic92 s Noctalia Plugins";
          url = "https://github.com/Mic92/noctalia-plugins";
        }
      ];
      states = {
        netbird = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        polkit-agent = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        keybind-cheatsheet = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        kagi-quick-search = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        mirror-mirror = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        model-usage = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        privacy-indicator = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };

        # mic92 plugins need the source hash prefix to match on-disk folder names
        "c4d277:display-config" = {
          enabled = true;
          sourceUrl = "https://github.com/Mic92/noctalia-plugins";
        };
        "c4d277:nostr-chat" = {
          enabled = true;
          sourceUrl = "https://github.com/Mic92/noctalia-plugins";
        };
      };
      version = 2;
    };
  };
}

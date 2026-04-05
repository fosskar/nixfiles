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
        model-usage = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };

        display-config = {
          enabled = true;
          sourceUrl = "https://github.com/Mic92/noctalia-plugins";
        };
      };
      version = 2;
    };
  };
}

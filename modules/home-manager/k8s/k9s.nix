_: {
  flake.modules.homeManager.k8s = _: {
    programs.k9s = {
      enable = true;

      settings.k9s = {
        liveViewAutoRefresh = true;
        refreshRate = 5;
        maxConnRetry = 15;

        ui = {
          enableMouse = false;
          headless = true;
          crumbsless = true;
        };

        logger = {
          tail = 200;
          buffer = 1000;
          sinceSeconds = 600;
        };
      };
    };
  };
}

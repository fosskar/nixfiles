_: {
  flake.modules.homeManager.k8s = _: {
    programs.k9s = {
      enable = true;

      settings.k9s = {
        ui = {
          enableMouse = false; # can scroll, but dont click. true = cant scroll, but can click
        };
        liveViewAutoRefresh = true;
        refreshRate = 1;
        maxConnRetry = 3;
      };
    };
  };
}

_: {
  security = {
    sudo-rs = {
      enable = true;
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };

    sudo = {
      enable = false;
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };
  };
}

_: {
  security = {
    sudo-rs.enable = false;
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };
  };
}

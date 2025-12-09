_: {
  console = {
    keyMap = "de";
    earlySetup = true;
  };

  systemd.services."serial-getty@".environment.TERM = "xterm-256color";
}

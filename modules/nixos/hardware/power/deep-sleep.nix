{
  flake.modules.nixos.deepSleep = {
    systemd.sleep.settings.Sleep = {
      SuspendState = "mem";
      MemorySleepMode = "deep";
    };
  };
}

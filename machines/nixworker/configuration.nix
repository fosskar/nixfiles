{
  self,
  nflib,
  ...
}:
{
  imports = [
    self.modules.nixos.btrfs
    self.modules.nixos.systemdBoot
    self.modules.nixos.tunedServerPowersave
    self.modules.nixos.nixbot
    self.modules.nixos.radicleMirror
    self.modules.nixos.tangledKnot
    self.modules.nixos.tangledSpindle
    self.modules.nixos.homeManager
    self.modules.nixos.nixAccessTokens
  ]
  ++ (nflib.scanPaths ./. { });

  srvos.boot.consoles = [ "tty0" ];

  # reap half-dead client connections (suspended laptop) within 90s so their
  # RemoteForward sockets stop accepting; otherwise kernel TCP keepalive holds
  # them for ~2h and the socket relays (users/workspace) hang on them
  services.openssh.settings = {
    ClientAliveInterval = 30;
    ClientAliveCountMax = 3;
  };

  programs.nix-ld.enable = true;
}

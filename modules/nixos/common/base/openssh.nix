{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      services.openssh = {
        enable = true;
        openFirewall = true;
        # socket activation - srvos doesn't set this
        startWhenNeeded = lib.mkDefault true;

        # mirrors srvos common/openssh.nix so we don't depend on it staying there
        settings = {
          X11Forwarding = false;
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
          UseDns = false;
          # unbind gnupg sockets if they exist
          StreamLocalBindUnlink = true;
          # reap half-dead connections (suspended client) within 90s so their
          # RemoteForward sockets stop accepting; otherwise kernel TCP
          # keepalive holds them for ~2h and socket relays hang on them
          ClientAliveInterval = 30;
          ClientAliveCountMax = 3;
        };
      };
    };
}

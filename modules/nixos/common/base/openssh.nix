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
        };
      };
    };
}

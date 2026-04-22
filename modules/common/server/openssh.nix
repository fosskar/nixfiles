{
  flake.modules.nixos.server = _: {
    # servers: no password auth
    services.openssh.settings.PasswordAuthentication = false;
  };
}

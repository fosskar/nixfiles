_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # forward ssh agent + gpg-agent extra socket (clan update, sops decrypt via local yubikey)
    settings."workspace" = {
      HostName = "nixworker.s";
      User = "simon";
      ForwardAgent = "yes";
      RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
    };
    # tangled knot push: public DNS points at the gateway, so reach nixworker's
    # knot sshd directly over the netbird mesh.
    settings."knot.fosskar.eu" = {
      HostName = "nixworker.s";
      User = "git";
    };
    settings."*" = {
      User = "root";
      AddKeysToAgent = "no";
      ControlMaster = "auto";
      ControlPath = "/tmp/ssh-%u-%r@%h:%p";
      ControlPersist = "10m";
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
      Compression = true;
      # FIXME: Work around gpg-agent smartcard signing failures with hostbound pubkey auth.
      PubkeyAuthentication = "unbound";
      UpdateHostKeys = "yes";
      StrictHostKeyChecking = "accept-new";
      # ensure ssh finds gpg-agent even when SSH_AUTH_SOCK is stripped
      # (e.g. nixos-rebuild-ng env sanitization, nixpkgs#493085)
      IdentityAgent = "/run/user/1000/gnupg/S.gpg-agent.ssh";
    };
  };
}

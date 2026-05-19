_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
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

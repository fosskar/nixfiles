_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # forward to fixed paths (StreamLocalBindUnlink swaps them per attach, so
    # persistent herdr panes never hold a stale socket): gpg-agent extra socket
    # (clan update, sops decrypt via local yubikey), the yubikey ssh agent
    # (git push, ssh to clan machines) and the remote-open browser socket
    settings."workspace" = {
      HostName = "nixworker.s";
      User = "simon";
      ForwardAgent = "yes";
      LocalForward = [ "54545 localhost:54545" ];
      RemoteForward = [
        "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra"
        "/run/user/1000/ssh-agent.sock /run/user/1000/gnupg/S.gpg-agent.ssh"
        "/run/user/1000/remote-open.sock /run/user/1000/remote-open.sock"
      ];
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

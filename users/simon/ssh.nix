_: {
  programs.ssh = {
    # tangled knot push: public DNS points at the gateway, so reach nixworker's
    # knot sshd directly over the netbird mesh.
    settings."knot.fosskar.eu" = {
      HostName = "nixworker.s";
      User = "git";
    };
    settings."*" = {
      User = "root";
      # ensure ssh finds gpg-agent even when SSH_AUTH_SOCK is stripped
      # (e.g. nixos-rebuild-ng env sanitization, nixpkgs#493085)
      IdentityAgent = "/run/user/1000/gnupg/S.gpg-agent.ssh";
      # clan hosts are trusted via the ssh-ca and forges via programs.ssh.knownHosts;
      # keep trust-on-first-use keys out of ~/.ssh/known_hosts, which the t3code
      # desktop app lists wholesale as ssh environment hosts
      UserKnownHostsFile = "~/.ssh/known_hosts.tofu";
    };
  };
}

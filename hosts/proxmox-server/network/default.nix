_: {
  imports = [
    ./fail2ban.nix
    ./firewall.nix
    ./network.nix
    ./openssh.nix
    ./optimize.nix
    ./resolved.nix
    ./tailscale.nix
  ];

  ## FIXME add initrd ssh host key
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      ignoreEmptyHostKeys = true;
    };
  };
}

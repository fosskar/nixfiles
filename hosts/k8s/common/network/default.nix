_: {
  imports = [
    ./fail2ban.nix
    ./firewall.nix
    ./networkmanager.nix
    ./openssh.nix
    ./optimize.nix
    ./resolved.nix
    ./tailscale.nix
  ];

  ## FIXME add initrd ssh host key
  #boot.initrd.network = {
  #  enable = true;
  #  ssh = {
  #    enable = true;
  #    port = 22;
  #    #hostKeys = [
  #    #  #FIXME this has to be manually uploaded during installation...
  #    #  # scp /tmp/initrd-ssh-key root@95.217.199.121:/mnt/var/lib/initrd-ssh-key
  #    #  "/var/lib/initrd-ssh-key"
  #    #];
  #  };
  #};
}

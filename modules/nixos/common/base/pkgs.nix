{
  flake.modules.nixos.base =
    { lib, pkgs, ... }:
    {
      environment = {
        defaultPackages = lib.mkForce [ ]; # no extra default packages are installed
        systemPackages = with pkgs; [
          coreutils
          curl
          dnsutils
          fd
          findutils
          lsof
          gitMinimal
          jq
          openssl
          tcpdump
          nmap
          wget
          unzip
          ripgrep
          yq-go
          pciutils
          nvme-cli
          smartmontools
        ];
      };
    };
}

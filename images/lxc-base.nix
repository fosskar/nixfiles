_: {
  imports = [
    ../modules/lxc
  ];

  users = {
    users = {
      root = {
        hashedPassword = "$y$j9T$yBays6ELhmm7.foDrjZhD0$GTwkBh4CkuFaBn20ydgHnEWd.igf2oIfZ4aOr99mJiD"; # set a invalid hashed or empty password "disables" root
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA openpgp:0xDA6712BE"
        ];
      };
    };
  };

  system.stateVersion = "25.05";
}

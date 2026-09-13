{
  flake.modules.nixos.workstation = _: {
    # nixpkgs' graphical-desktop.nix defaults speech-dispatcher on for any
    # graphical session (screen-reader support); its closure is 1.3 GB of
    # espeak-ng and mbrola voices and nothing here speaks
    services.speechd.enable = false;
  };
}

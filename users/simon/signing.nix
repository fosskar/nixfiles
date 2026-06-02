_: {
  # per-user ssh signing key for git and jujutsu aspects
  programs.git.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA";
  programs.jujutsu.settings.signing.key =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3AsDe157avF+iFa1TavZHwjDpugyePDqJ6gaRNzGIA";
}

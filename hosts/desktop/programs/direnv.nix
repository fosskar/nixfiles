{ ... }:
{
  programs.direnv = {
    enable = true;

    # Shut up, direnv. SHUT. UP.
    silent = true;

    # Faster, persistent implementation of use_nix and use_flake in
    # direnv based shells.
    nix-direnv.enable = true;

    # Enable loading direnv in nix-shell, nix shell or nix develop
    loadInNixShell = true;
  };
}

{ inputs, ... }:
{
  flake.modules.nixos.umbriel = {
    imports = [ inputs.umbriel.nixosModules.default ];

    # registers the session for the greeter and installs xdg-desktop-portal-umbriel
    programs.umbriel.enable = true;
  };
}

{ inputs, ... }:
{
  imports = [ inputs.nix-citizen.nixosModules.StarCitizen ];

  nix-citizen.starCitizen = {
    enable = true;
    umu.enable = true;
    preCommands = ''
      export DXVK_HUD=compiler;
      export MANGO_HUD=1;
      export dual_color_blend_by_location="true";
    '';
    helperScript = {
      enable = true;
    };
    setLimits = false;
  };
}

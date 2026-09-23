{ inputs, ... }:
{
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code-desktop
      ];
    };
}

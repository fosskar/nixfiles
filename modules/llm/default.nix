{ inputs, lib, ... }:
let
  skillsFrom =
    root:
    lib.mapAttrs (name: _: root + "/${name}") (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir root)
    );
in
{
  # skills are shared data with several consumers. home-manager installs all
  # of them into agent dirs, and nixos services select individual skills.
  flake.llm.skills = skillsFrom ./skills // skillsFrom (inputs.pi-pack + "/skills");

  flake.llm.souls.tars = ./souls/TARS.md;
}

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
  flake.llm.souls.rocky = ./souls/ROCKY.md;
  # SOUL.md from github.com/will-assistant/openclaw-agents at 2c04d54d (MIT)
  flake.llm.souls.ted-lasso = ./souls/TED-LASSO.md;
  flake.llm.souls.rick-sanchez = ./souls/RICK-SANCHEZ.md;
  flake.llm.souls.angela-merkel = ./souls/ANGELA-MERKEL.md;
  flake.llm.souls.captain-picard = ./souls/CAPTAIN-PICARD.md;
}

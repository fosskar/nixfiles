{
  flake.modules.nixos.opencrow =
    { config, ... }:
    {
      clan.core.vars.generators.opencrow-location = {
        files.".env" = { };
        prompts.dawarich-api-key = {
          description = "Dawarich API key for simon (Dawarich -> Account -> copy API key)";
          type = "hidden";
          persist = true;
        };
        script = ''
          echo "DAWARICH_API_KEY=$(cat "$prompts/dawarich-api-key")" > "$out/.env"
        '';
      };

      services.opencrow = {
        environmentFiles = [ config.clan.core.vars.generators.opencrow-location.files.".env".path ];
        skills.location = ./skills/location;
      };
    };
}

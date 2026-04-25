{
  flake.modules.nixos.opencrow =
    { config, ... }:
    let
      paperlessHost = "docs.${config.domains.local}";
    in
    {
      clan.core.vars.generators.opencrow-paperless = {
        files.api-token.secret = true;
        prompts.api-token.description = "paperless-ngx api token for opencrow";
        script = ''
          cp "$prompts/api-token" "$out/api-token"
        '';
      };

      services.opencrow = {
        skills.paperless = ./skills/paperless;
        credentialFiles."paperless-api-token" =
          config.clan.core.vars.generators.opencrow-paperless.files.api-token.path;
      };

      services.opencrow.environment = {
        PAPERLESS_URL = "https://${paperlessHost}";
      };
    };
}

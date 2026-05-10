{
  flake.modules.nixos.opencrow = _: {
    clan.core.vars.generators.opencrow-paperless = {
      files.api-token.secret = true;
      prompts.api-token.description = "paperless-ngx api token for opencrow";
      script = ''
        cp "$prompts/api-token" "$out/api-token"
      '';
    };
  };
}

{ ... }:
{
  imports = [
    ../../modules/secrets
  ];

  # optional: configure secrets for arr services
  # uncomment and create secret files in nixsecrets repo when needed

  # age.secrets = {
  #   # example: api keys for service integration
  #   # arr-api-keys = {
  #   #   rekeyFile = "${inputs.nixsecrets}/agenix/nixinfra/arr/api-keys.age";
  #   # };
  # };
}

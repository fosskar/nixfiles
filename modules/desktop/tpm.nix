{
  lib,
  config,
  pkgs,
  ...
}:
{
  security.tpm2 = {
    enable = lib.mkDefault true;
    applyUdevRules = lib.mkDefault true;
    abrmd.enable = lib.mkDefault true;
    tctiEnvironment.enable = lib.mkDefault true;
    pkcs11.enable = lib.mkDefault true;
  };

  # add wheel users to tss group for TPM access
  users.groups.tss.members = config.users.groups.wheel.members;

  environment.systemPackages = lib.mkIf config.security.tpm2.enable [
    pkgs.tpm2-tools
    pkgs.tpm2-tss
    pkgs.age-plugin-tpm
  ];
}

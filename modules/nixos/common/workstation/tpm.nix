{
  flake.modules.nixos.workstation =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      boot.initrd.systemd.tpm2.enable = lib.mkDefault true;

      security.tpm2 = {
        enable = lib.mkDefault true;
        applyUdevRules = lib.mkDefault true;
        abrmd.enable = lib.mkDefault true;
        tctiEnvironment.enable = lib.mkDefault true;
        pkcs11.enable = lib.mkDefault false;
      };

      # add wheel users to tss group for TPM access
      users.groups.tss.members = lib.mkAfter config.users.groups.wheel.members;

      environment.systemPackages = lib.mkIf config.security.tpm2.enable [
        pkgs.tpm2-tools
        pkgs.tpm2-tss
        pkgs.age-plugin-tpm
      ];
    };
}

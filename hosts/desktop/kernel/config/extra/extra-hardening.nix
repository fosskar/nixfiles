{ lib, ... }:
let
  inherit (lib.kernel) yes no unset;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) mkForce;
in
{
  boot.kernelPatches = [
    {
      name = "hardening";
      patch = null;
      extraStructuredConfig = mapAttrs (_: mkForce) {
        ### Extra hardening. Don't enable this blidnly.
        ## https://wiki.gentoo.org/wiki/Integrity_Measurement_Architecture
        ## https://wiki.gentoo.org/wiki/Extended_Verification_Module
        ## https://www.kernel.org/doc/html/v4.14/admin-guide/LSM/Smack.html

        ## IMA - Integrity Measurement Architecture. In order to enable this, we need to enable kernel options below and set kernel boot option "lsm=integrity"
        # Need to be implement very carefully.
        # Options below only enabled in xanmod github. Why cachyos-hardened not enabling them?
        IMA = yes;
        IMA_KEXEC = yes;
        IMA_MEASURE_PCR_IDX = "10";
        IMA_LSM_RULES = yes;
        IMA_NG_TEMPLATE = yes;
        IMA_DEFAULT_TEMPLATE = "ima-ng";
        IMA_DEFAULT_HASH_SHA256 = yes;
        IMA_DEFAULT_HASH = "sha256"; # or sha512
        #IMA_DEFAULT_HASH_SHA512 # also are option.
        IMA_APPRAISE = yes;
        IMA_ARCH_POLICY = yes;
        IMA_APPRAISE_BOOTPARAM = yes;
        IMA_APPRAISE_MODSIG = yes;
        IMA_MEASURE_ASYMMETRIC_KEYS = yes;
        IMA_QUEUE_EARLY_BOOT_KEYS = yes;
        IMA_SECURE_AND_OR_TRUSTED_BOOT = yes;

        # Only kernel options below enabled in cachyos-hardened.
        INTEGRITY_SIGNATURE = yes;
        INTEGRITY_ASYMMETRIC_KEYS = yes;
        INTEGRITY_TRUSTED_KEYRING = yes;
        INTEGRITY_PLATFORM_KEYRING = yes;
        INTEGRITY_MACHINE_KEYRING = yes;

        ## EVM - Extended Verification Module
        # Disabled in cachyos hardened. Gento also warns about enabling this.
        # In order to enable EVM we need:
        EVM = yes;
        #TCG_TPM enabled as module already.

        #Other EVM related flags.
        EVM_ATTR_FSUUID = yes;
        EVM_EXTRA_SMACK_XATTRS = yes; # if SMACK Enabled? SMACK disabled also by default.
        EVM_ADD_XATTRS = yes;
        # also INTEGRITY required and boot.kernelParams "evm=fix" on first boot.
        # Then, we need set up keys in tpm. More in gentoo wiki: https://wiki.gentoo.org/wiki/Extended_Verification_Module

        ## SMACK
        # below is copy-pasted from cachyos-hardened.
        SECURITY_SMACK = yes;
        SECURITY_SMACK_BRINGUP = yes;
        SECURITY_SMACK_NETFILTER = yes;
        SECURITY_SMACK_APPEND_SIGNALS = yes;
        #DEFAULT_SECURITY_SMACK is not set # I guess cachyos just leave it up to user, what he want to use.

        ### CONFIG_DEFAULT_SECURITY for comparison.
        ## https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/security-enhanced_linux/chap-security-enhanced_linux-introduction#chap-Security-Enhanced_Linux-Introduction
        ## https://cateee.net/lkddb/web-lkddb/SECURITY_LOADPIN.html
        ## https://cateee.net/lkddb/web-lkddb/SECURITY_SAFESETID.html

        # Cachyos ( hardened ) settings:
        # CONFIG_DEFAULT_SECURITY_SELINUX is not set  # support of this enabled, just not as "DEFAULT".
        # CONFIG_DEFAULT_SECURITY_SMACK is not set    # Same as above.
        # CONFIG_DEFAULT_SECURITY_TOMOYO is not set   # Same as above.
        # CONFIG_DEFAULT_SECURITY_APPARMOR is not set # Same as above.
        #CONFIG_SECURITY_LOADPIN = yes; # Any files read through the kernel file reading interface (kernel modules, firmware, kexec images, security policy) can be pinned to the first filesystem used for loading. When enabled, any files that come from other filesystems will be rejected.
        #CONFIG_SECURITY_LOADPIN_ENFORCE = yes;
        #CONFIG_SECURITY_SAFESETID = yes; # SafeSetID is an LSM module that gates the setid family of syscalls to restrict UID/GID transitions from a given UID/GID to only those approved by a system-wide whitelist.
        #CONFIG_SECURITY_LOCKDOWN_LSM = yes;
        #CONFIG_DEFAULT_SECURITY_DAC = yes; # Unix Discretionary Access Controls. Not much info, outside redhat "SELinux introduction". Most distro use apparmor as "DEFAULT" instead.
        #CONFIG_LSM = "landlock,lockdown,yama,integrity,bpf";

        # Xanmod ( github config ) settings:
        # CONFIG_DEFAULT_SECURITY_SELINUX is not set # support of this enabled in kernel, just not as "DEFAULT".
        # CONFIG_DEFAULT_SECURITY_SMACK is not set   # Same as above.
        # CONFIG_DEFAULT_SECURITY_TOMOYO is not set  # Same as above.
        # CONFIG_SECURITY_LOADPIN is not set         # Disabled
        # CONFIG_SECURITY_LOADPIN_ENFORCE is not set # Disabled
        # = yes;
        #LSM = yes;
        #PPARMOR = yes;
        # CONFIG_DEFAULT_SECURITY_DAC is not set
        #CONFIG_LSM = "landlock,lockdown,yama,integrity,apparmor";

        # Xanmod NixOS settings:
        # CONFIG_DEFAULT_SECURITY_TOMOYO is not set # Disabled in kernel also
        # CONFIG_DEFAULT_SECURITY_SELINUX is not set # Disabled as "DEFAULT", but in kernel enabled.
        # CONFIG_DEFAULT_SECURITY_DAC is not set  # Disabled
        # CONFIG_SECURITY_SMACK is not set # Disabled in kernel also
        # CONFIG_SECURITY_LOADPIN is not set # Disabled
        # CONFIG_SECURITY_LOADPIN_ENFORCE is not set # Disabled
        # CONFIG_SECURITY_SAFESETID is not set # Disabled
        #CONFIG_SECURITY_LOCKDOWN_LSM = yes; # Enabled in "security.nix" config.
        #CONFIG_DEFAULT_SECURITY_APPARMOR = yes;
        #CONFIG_LSM = "landlock,lockdown,yama,loadpin,safesetid,selinux,smack,tomoyo,apparmor,bpf"; # why smack, tomoyo, loadpin, safesetid even here, when kernel related options disabled? Doubt it will cause any issue, it's just ugly.
      };
    }
  ];
}

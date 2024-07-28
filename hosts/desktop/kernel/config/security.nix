{ lib, ... }:
let
  inherit (lib.kernel) yes no freeform;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) mkForce;
in
{
  boot.kernelPatches = [
    {
      # enable lockdown LSM
      name = "kernel-lockdown-lsm";
      patch = null;
      extraStructuredConfig = mapAttrs (_: mkForce) {
        SECURITY_LOCKDOWN_LSM = yes;
        LOCKDOWN_LSM_EARLY = yes;
        LOCK_DOWN_KERNEL_FORCE_CONFIDENTIALITY = yes;

        # used to avoid a systemd error:
        # systemd[1]: bpf-lsm: Failed to load BPF object: Invalid argument
        BPF_LSM = yes;
      };
    }
    {
      name = "security";
      patch = null;
      extraStructuredConfig = mapAttrs (_: mkForce) {
        # Reason to enable it: https://lore.kernel.org/lkml/20180109180429.1115005-1-ast@kernel.org/
        # In short: "To make attacker job harder introduce BPF_JIT_ALWAYS_ON config
        # option that removes interpreter from the kernel in favor of JIT-only mode.
        # So far eBPF JIT is supported by:
        # x64, arm64, arm32, sparc64, s390, powerpc64, mips64"
        # It was enabled in xanmod git kernel, cachyos-bore and cachyos hardened, but disabled in nixos xanmod.
        # opensnitch, wine and some other stuff using this. Need to make sure nothing breaks.
        #BPF_JIT_ALWAYS_ON = yes;

        ARCH_MMAP_RND_BITS = freeform "32"; # https://cateee.net/lkddb/web-lkddb/ARCH_MMAP_RND_BITS.html
        # NixOS xanmod kernel zcat output: RND_BITS_MIN=28, RND_BITS_MAX=32, RND_BITS=28, when in xanmod github it's 28,32,32. Cachyos also use 28,32,32. Same for hardened kernel.
        # Weird. Why NixOS xanmod set RND_BITS to MIN instead of MAX like other kernels do?

        ARCH_MMAP_RND_COMPAT_BITS = freeform "16"; # same as above. COMPAT_BITS_MIN=8,COMPAT_BITS_MAX=16,COMPAT_BITS=8, when in xanmod github it's 8,16,16 and cachyos 8,16,16.

        RANDOMIZE_KSTACK_OFFSET_DEFAULT = yes; # https://www.phoronix.com/news/randomize_kstack_offset-perf .Xanmod github and cachyos enabling this also.

        ### Load only signed modules. #Novidia and openrazer drivers modules need to sign, or you will get system without gpu/mouse/keyboard drivers. Hmm, how can I do this in NixOS declaratively?
        ## https://cateee.net/lkddb/web-lkddb/MODULE_SIG.html
        ## https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/module-signing.rst
        MODULE_SIG_FORMAT = yes;
        MODULE_SRCVERSION_ALL = yes;

        MODULE_SIG = yes;
        # !!!WARNING!!! If you enable this option, you MUST make sure that the module DOES NOT get stripped after being signed. This includes the debuginfo strip done by some packagers (such as rpmbuild) and inclusion into an initramfs that wants the module size reduced
        # You should enable MODULE_SIG option if you wish to use either SECURITY_LOCKDOWN_LSM or lockdown functionality imposed via another LSM - otherwise unsigned modules will be loadable regardless of the lockdown policy.
        MODULE_SIG_FORCE = yes;
        MODULE_SIG_ALL = yes;
        MODULE_SIG_SHA512 = yes;
        MODULE_SIG_HASH = freeform "sha512";
        MODULE_COMPRESS_NONE = yes;
        # Enabled in cachyos hardened.
        MODULE_SIG_KEY = freeform "certs/signing_key.pem";
        # CONFIG_MODULE_SIG_KEY_TYPE_RSA is not set
        MODULE_SIG_KEY_TYPE_RSA = yes;

        BLK_CGROUP_FC_APPID = yes; # https://cateee.net/lkddb/web-lkddb/BLK_CGROUP_FC_APPID.html enabled in cachy + git xanmod.

        SHUFFLE_PAGE_ALLOCATOR = yes; # https://cateee.net/lkddb/web-lkddb/SHUFFLE_PAGE_ALLOCATOR.html Enabled in cachy + xanmod git. For extra security :'page_alloc.shuffle' kernel command line parameter required.

        # https://access.redhat.com/articles/20484 and https://wiki.debian.org/mmap_min_addr .
        # NixOS default is 4096 as RedHat and Debian suggest. I probably want to set higher, coz quote:
        # The downside to preventing applications from mmap'ing low virtual memory addresses is that certain applications depend on this functionality.
        # dosemu, qemu and wine are three such applications"
        DEFAULT_MMAP_MIN_ADDR = freeform "65536"; # xanmod and cachyos-bore defaults. CachyOS hardened also set to 65536.

        RESET_ATTACK_MITIGATION = yes; # Request to clear ram before reboot. Enabled in xanmod github and cachyos hardened only. https://cateee.net/lkddb/web-lkddb/RESET_ATTACK_MITIGATION.html

        ## Hardening of kernel data structures
        #BUG_ON_DATA_CORRUPTION = yes; # It's disabled in xanmod github/nixos. Enabled in cachyos-hardened.

        RANDSTRUCT_FULL = yes; # Enabled in Cachyos-hardened. https://cateee.net/lkddb/web-lkddb/RANDSTRUCT_FULL.html.
        RANDSTRUCT = yes;

        GCC_PLUGIN_RANDSTRUCT = yes; # https://cateee.net/lkddb/web-lkddb/GCC_PLUGIN_RANDSTRUCT.html If we compiling with gcc. Clang implemintation looks better I think.

        # RANDSTRUCT_NONE is not set #Enabled in xanmod github and nixos xanmod
        # RANDSTRUCT_PERFORMANCE is not set

        ## INIT settings
        # Source: https://github.com/torvalds/linux/blob/master/security/Kconfig.hardening

        # INIT_STACK_NONE
        # Disable automatic stack variable initialization.
        # This leaves the kernel vulnerable to the standard classes of uninitialized stack variable exploits and information exposures, but provide small performance increase.
        # Enabled in xanmod github kernel, but DISABLED in NixOS xanmod and cachyos kernels."
        # INIT_STACK_ALL_ZERO enabled by default in cachyos hardened and xanmod NixOS instead.

        # INIT_ALLOC_DEFAULT_ON
        # This has the effect of setting "init_on_alloc=1" on the kernel
        # command line. This can be disabled with "init_on_alloc=0".
        # When "init_on_alloc" is enabled, all page allocator and slab
        # allocator memory will be zeroed when allocated, eliminating
        # many kinds of "uninitialized heap memory" flaws, especially
        # heap content exposures. The performance impact varies by
        # workload, but most cases see <1% impact. Some synthetic
        # workloads have measured as high as 7%."
        INIT_ON_ALLOC_DEFAULT_ON = yes; # Enabled in cachyos hardened and xanmod git kernel, but disabled in NixOS xanmod kernel.

        # INIT_ON_FREE_DEFAULT
        # This has the effect of setting "init_on_free=1" on the kernel
        # command line. This can be disabled with "init_on_free=0".
        # Similar to "init_on_alloc", when "init_on_free" is enabled,
        # all page allocator and slab allocator memory will be zeroed
        # when freed, eliminating many kinds of "uninitialized heap memory"
        # flaws, especially heap content exposures. The primary difference
        # with "init_on_free" is that data lifetime in memory is reduced,
        # as anything freed is wiped immediately, making live forensics or
        # cold boot memory attacks unable to recover freed memory contents.
        # The performance impact varies by workload, but is more expensive
        # than "init_on_alloc" due to the negative cache effects of
        # touching "cold" memory areas. Most cases see 3-5% impact. Some
        # synthetic workloads have measured as high as 8%."
        INIT_ON_FREE_DEFAULT_ON = yes; # Enabled only in cachyos hardened kernel.

        # CachyOS hardened also have CONFIG_PAGE_SANITIZE_VERIFY=y and CONFIG_SLAB_SANITIZE_VERIFY=y, but nothing like that in xanmod kernel config.
        # Maybe out-of-tree kernel patches required for that?
      };
    }
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
        #IMA = yes;
        #IMA_KEXEC = yes;
        #IMA_MEASURE_PCR_IDX = "10";
        #IMA_LSM_RULES = yes;
        #IMA_NG_TEMPLATE = yes;
        #IMA_DEFAULT_TEMPLATE = "ima-ng";
        #IMA_DEFAULT_HASH_SHA256 = yes;
        #IMA_DEFAULT_HASH = "sha256"; # or sha512
        #IMA_DEFAULT_HASH_SHA512 # also are option.
        #IMA_APPRAISE = yes;
        #IMA_ARCH_POLICY = yes;
        #IMA_APPRAISE_BOOTPARAM = yes;
        #IMA_APPRAISE_MODSIG = yes;
        #IMA_MEASURE_ASYMMETRIC_KEYS = yes;
        #IMA_QUEUE_EARLY_BOOT_KEYS = yes;
        #IMA_SECURE_AND_OR_TRUSTED_BOOT = yes;

        # Only kernel options below enabled in cachyos-hardened.
        #INTEGRITY_SIGNATURE = yes;
        #INTEGRITY_ASYMMETRIC_KEYS = yes;
        #INTEGRITY_TRUSTED_KEYRING = yes;
        #INTEGRITY_PLATFORM_KEYRING = yes;
        #INTEGRITY_MACHINE_KEYRING = yes;

        ## EVM - Extended Verification Module
        # Disabled in cachyos hardened. Gento also warns about enabling this.
        # In order to enable EVM we need:
        #EVM = yes;
        #TCG_TPM enabled as module already.

        #Other EVM related flags.
        #EVM_ATTR_FSUUID = yes;
        #EVM_EXTRA_SMACK_XATTRS = yes; # if SMACK Enabled? SMACK disabled also by default.
        #EVM_ADD_XATTRS = yes;
        # also INTEGRITY required and boot.kernelParams "evm=fix" on first boot.
        # Then, we need set up keys in tpm. More in gentoo wiki: https://wiki.gentoo.org/wiki/Extended_Verification_Module

        ## SMACK
        # below is copy-pasted from cachyos-hardened.
        #SECURITY_SMACK = yes;
        #SECURITY_SMACK_BRINGUP = yes;
        #SECURITY_SMACK_NETFILTER = yes;
        #SECURITY_SMACK_APPEND_SIGNALS = yes;
        #DEFAULT_SECURITY_SMACK is not set # I guess cachyos just leave it up to user, what he want to use.

        ### CONFIG_DEFAULT_SECURITY for comparison.
        ## https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/security-enhanced_linux/chap-security-enhanced_linux-introduction#chap-Security-Enhanced_Linux-Introduction
        ## https://cateee.net/lkddb/web-lkddb/SECURITY_LOADPIN.html
        ## https://cateee.net/lkddb/web-lkddb/SECURITY_SAFESETID.html

        # Cachyos ( hardened ) settings:
        # CONFIG_DEFAULT_SECURITY_SELINUX is not set  # support of this enabled, just not as "DEFAULT".
        # CONFIG_DEFAULT_SECURITY_SMACK is not set    # Same as aboSECURITY_LOCKDOWN_LSMve.
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
        #CONFIG_SECURITY_SAFESETID = yes;
        #CONFIG_SECURITY_LOCKDOWN_LSM = yes;
        #CONFIG_DEFAULT_SECURITY_APPARMOR = yes;
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
        #CONFIG_SECURITY_LOCKDOWN_LSM = yes;
        #CONFIG_DEFAULT_SECURITY_APPARMOR = yes;
        #CONFIG_LSM = "landlock,lockdown,yama,loadpin,safesetid,selinux,smack,tomoyo,apparmor,bpf"; # why smack, tomoyo, loadpin, safesetid even here, when kernel related options disabled? Doubt it will cause any issue, it's just ugly.

        # best combination of cchyos xanmod xanmodnixos from above
        #SECURITY_LOADPIN = yes;
        #SECURITY_LOADPIN_ENFORCE = yes;
        #SECURITY_SAFESETID = yes;
        #SECURITY_LOCKDOWN_LSM = yes;
        #DEFAULT_SECURITY_APPARMOR = yes;
        #DEFAULT_SECURITY_DAC = yes;
        #LSM = freeform "landlock,lockdown,yama,loadpin,safesetid,integrity,apparmor,bpf,selinux";
      };
    }
  ];
}

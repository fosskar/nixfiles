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

        MODULE_SIG = yes;
        # !!!WARNING!!! If you enable this option, you MUST make sure that the module DOES NOT get stripped after being signed. This includes the debuginfo strip done by some packagers (such as rpmbuild) and inclusion into an initramfs that wants the module size reduced
        # You should enable MODULE_SIG option if you wish to use either SECURITY_LOCKDOWN_LSM or lockdown functionality imposed via another LSM - otherwise unsigned modules will be loadable regardless of the lockdown policy.

        MODULE_SIG_SHA512 = yes;
        MODULE_SIG_FORCE = yes;

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
  ];
}

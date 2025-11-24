{ lib, ... }:
{
  security = {
    protectKernelImage = true; # disables hibernation

    # Breaks virtd, wireguard, iptables and many more features by
    # disallowing them from loading modules during runtime. You may
    # enable this module if you wish, but do make sure that the
    # necessary modules are loaded declaratively before doing so.
    # Failing to add those modules may result in an unbootable system!
    lockKernelModules = false;

    # Force-enable the Page Table Isolation (PTI) Linux kernel feature
    # helps mitigate Meltdown and prevent some KASLR bypasses.
    # maybe more pferoamnce when set to false
    forcePageTableIsolation = false;

    # User namespaces are required for sandboxing. Better than nothing imo.
    allowUserNamespaces = true;

    allowSimultaneousMultithreading = true;

    # This is required by podman to run containers in rootless mode.
    unprivilegedUsernsClone = true;
  };

  boot = {
    kernel.sysctl = {
      ### SECURITY
      # The Magic SysRq key is a key combo that allows users connected to the
      # system console of a Linux kernel to perform some low-level commands.
      # Disable it, since we don't need it, and is a potential security concern.
      "kernel.sysrq" = lib.mkForce 0;
      # Hide kptrs even for processes with CAP_SYSLOG
      # also prevents printing kernel pointers
      "kernel.kptr_restrict" = 2;
      # Disable ftrace debugging
      "kernel.ftrace_enabled" = false;
      # Avoid kernel memory address exposures via dmesg (this value can also be set by CONFIG_SECURITY_DMESG_RESTRICT).
      "kernel.dmesg_restrict" = 1;
      # This action will speed up your boot and shutdown, because one less module is loaded. Additionally disabling watchdog timers increases performance and lowers power consumption
      # Disable NMI watchdog
      "kernel.nmi_watchdog" = 0;
      # Prevent creating files in potentially attacker-controlled environments such
      # as world-writable directories to make data spoofing attacks more difficult
      "fs.protected_fifos" = 2;
      # Prevent unintended writes to already-created files
      "fs.protected_regular" = 2;
      # Disable SUID binary dump
      "fs.suid_dumpable" = 0;
      # Prevent unprivileged users from creating hard or symbolic links to files
      "fs.protected_symlinks" = 1;
      "fs.protected_hardlinks" = 1;
      # Prevent boot console kernel log information leaks
      "kernel.printk" = "3 3 3 3";
      # Restrict loading TTY line disciplines to the CAP_SYS_MODULE capability to
      # prevent unprivileged attackers from loading vulnerable line disciplines with
      # the TIOCSETD ioctl
      "dev.tty.ldisc_autoload" = 0;
      # Kexec allows replacing the current running kernel. There may be an edge case where
      # you wish to boot into a different kernel, but I do not require kexec. Disabling it
      # patches a potential security hole in our system.
      "kernel.kexec_load_disabled" = true;
      # Borrowed by NixOS/nixpkgs. Since the security module does not explain what those
      # options do, it is up you to educate yourself dear reader.
      # See:
      #  - <https://docs.kernel.org/admin-guide/sysctl/vm.html#mmap-rnd-bits>
      #  - <https://docs.kernel.org/admin-guide/sysctl/vm.html#mmap-min-addr>
      "vm.mmap_rnd_bits" = 32;
      "vm.mmap_min_addr" = 65536;
      # The value controls the tendency of the kernel to reclaim the memory which is used for caching of directory and inode objects (VFS cache).
      # Lowering it from the default value of 100 makes the kernel less inclined to reclaim VFS cache (do not set it to 0, this may produce out-of-memory conditions)
      "vm.vfs_cache_pressure" = 50;
      # Contains, as a bytes of total available memory that contains free pages and reclaimable
      # pages, the number of pages at which a process which is generating disk writes will itself start
      # writing out dirty data.
      "vm.dirty_bytes" = 268435456;
      # Contains, as a bytes of total available memory that contains free pages and reclaimable
      # pages, the number of pages at which the background kernel flusher threads will start writing out
      # dirty data.
      "vm.dirty_background_bytes" = 67108864;
      # The kernel flusher threads will periodically wake up and write old data out to disk.  This
      # tunable expresses the interval between those wakeups, in 100'ths of a second (Default is 500).
      "vm.dirty_writeback_centisecs" = 1500;
      "dev.hpet.max-user-freq" = 3072;

      # bpf
      #"kernel.unprivileged_bpf_disabled" = 0; # # allow user-space apps to use bpf
      "net.core.bpf_jit_enable" = 1;
      "net.core.bpf_jit_harden" = 0;
    };
    kernelParams = [
      # I'm sure we break hibernation in at least 5 other sections of this config, so
      # let's disable hibernation explicitly. Allowing hibernation makes it possible
      # to replace the booted kernel with a malicious one, akin to kexec. This helps
      # us prevent an attack called "Evil Maid" where an attacker with physical access
      # to the device. P.S. I chose to mention "Evil Maid" specifically because it sounds
      # funny. Do not think that is the only attack you are vulnerable to.
      # See: <https://en.wikipedia.org/wiki/Evil_maid_attack>
      "nohibernate" # disabled in cachyos kernel, but in case we switch, always keep it disabled for desktop
      # make stack-based attacks on the kernel harder
      "randomize_kstack_offset=on"
      # Disable vsyscalls as they are obsolete and have been replaced with vDSO.
      # vsyscalls are also at fixed addresses in memory, making them a potential
      # target for ROP attacks
      # this breaks really old binaries for security
      "vsyscall=none"
      # reduce most of the exposure of a heap attack to a single cache
      # Disable slab merging which significantly increases the difficulty of heap
      # exploitation by preventing overwriting objects from merged caches and by
      # making it harder to influence slab cache layout but costs performance
      #"slab_nomerge"
      # Disable debugfs which exposes a lot of sensitive information about the
      # kernel. Some programs, such as powertop, use this interface to gather
      # information about the system, but it is not necessary for the system to
      # actually publish those. I can live without it.
      # doesnt work in combination with scx-ladv scheduler
      #"debugfs=off"
      # Sometimes certain kernel exploits will cause what is known as an "oops".
      # This parameter will cause the kernel to panic on such oopses, thereby
      # preventing those exploits
      "oops=panic"
      # Only allow kernel modules that have been signed with a valid key to be
      # loaded, which increases security by making it much harder to load a
      # malicious kernel module
      "module.sig_enforce=1"
      # The kernel lockdown LSM can eliminate many methods that user space code
      # could abuse to escalate to kernel privileges and extract sensitive
      # information. This LSM is necessary to implement a clear security boundary
      # between user space and the kernel
      #  integrity: kernel features that allow userland to modify the running kernel
      #             are disabled
      #  confidentiality: kernel features that allow userland to extract confidential
      #             information from the kernel are also disabled
      # ArchWiki recommends opting in for "integrity", however since we avoid modifying
      # running kernel (by the virtue of using NixOS and locking module hot-loading) the
      # confidentiality mode is a better solution.
      # FYI: integrity is better solution when using sched-ext scheduler with BPF functionality.
      "lockdown=none"
      # enable buddy allocator free poisoning
      #  on: memory will befilled with a specific byte pattern
      #      that is unlikely to occur in normal operation.
      #  off (default): page poisoning will be disabled
      "page_poison=on"
      # performance improvement for direct-mapped memory-side-cache utilization
      # reduces the predictability of page allocations
      "page_alloc.shuffle=1"
      # for debugging kernel-level slab issues
      #"slub_debug=FZP"
      # ignore access time (atime) updates on files
      # except when they coincide with updates to the ctime or mtime
      "rootflags=noatime"
      # linux security modules. default for cachyos_latest: capability,landlock,lockdown,yama,bpf
      # possible values: landlock,lockdown,yama,loadpin,safesetid,integrity,apparmor,bpf,tomoyo,selinux
      #"lsm=capability,landlock,lockdown,yama"
      # prevent the kernel from blanking plymouth out of the fb
      #"fbcon=nodefer"
      # the format that will be used for integrity audit logs
      #  0 (default): basic integrity auditing messages
      #  1: additional integrity auditing messages
      "integrity_audit=1"

      # https://en.wikipedia.org/wiki/Kernel_page-table_isolation
      # auto means kernel will automatically decide the pti state
      "pti=off" # on | off | auto

      # CPU idle behaviour only Intel CPU
      #  poll: slightly improve performance at cost of a hotter system (not recommended)
      #  halt: halt is forced to be used for CPU idle
      #  nomwait: Disable mwait for CPU C-states
      #"idle=nomwait" # poll | halt | nomwait

      # disable usb autosuspend
      "usbcore.autosuspend=-1"

      # disable displaying of the built-in Linux logo
      "logo.nologo"

      # disable watchdog timer
      "nowatchdog"

      ''acpi_osi="Windows 2020"''

      # quite boot setup
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    blacklistedKernelModules = [
      # Obscure network protocols
      "dccp" # Datagram Congestion Control Protocol
      "snd_hda_intel"
      "sctp" # Stream Control Transmission Protocol
      "rds" # Reliable Datagram Sockets
      "tipc" # Transparent Inter-Process Communication
      "n-hdlc" # High-level Data Link Control
      "netrom" # NetRom
      "x25" # X.25
      "ax25" # Amateur X.25
      "rose" # ROSE
      "decnet" # DECnet
      "econet" # Econet
      "af_802154" # IEEE 802.15.4
      "ipx" # Internetwork Packet Exchange
      "appletalk" # Appletalk
      "psnap" # SubnetworkAccess Protocol
      "p8022" # IEEE 802.3
      "p8023" # Novell raw IEEE 802.3
      "can" # Controller Area Network
      "atm" # ATM

      "ath3k"
      # Blacklist the AMD SP5100 TCO Watchdog/Timer module (Required for Ryzen cpus)
      "sp5100_tco"
      # Blacklist the Intel TCO Watchdog/Timer module
      "iTCO_wdt"
    ];
  };
}

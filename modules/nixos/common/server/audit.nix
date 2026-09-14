{
  flake.modules.nixos.server = _: {
    security.audit = {
      enable = true;
      rules = [
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/group -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
        "-w /etc/sudoers -p wa -k privilege"
        "-w /etc/ssh -p wa -k sshd"
        "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k modules"
        # every command run from a login session (ssh, clan deploys); daemons excluded
        "-a always,exit -F arch=b64 -S execve -F auid!=unset -k session_exec"
      ];
    };
    # auditd claims the kernel audit socket so events stop going to printk;
    # journald still gets its multicast copy and ships it to victorialogs
    security.auditd.enable = true;

    # rules that watch service data or filter by user name need the mounts
    # and /etc/passwd; the upstream unit runs before both
    systemd.services.audit-rules-nixos.after = [
      "local-fs.target"
      "userborn.service"
    ];
  };
}

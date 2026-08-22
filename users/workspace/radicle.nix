{
  # always-on node on the workstation; upstream only auto-starts the node via
  # lazy sockets, without lazy the unit has no [Install] section
  systemd.user.services.radicle-node.Install.WantedBy = [ "default.target" ];
}

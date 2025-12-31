_: {
  programs = {
    claude-code = {
      settings = {
        permissions = {

          #additionalDirectories = [
          #  "../docs/"
          #];
          ask = [
            "Bash(git checkout:*)"
            "Bash(git commit:*)"
            "Bash(git merge:*)"
            "Bash(git pull:*)"
            "Bash(git push:*)"
            "Bash(git rebase:*)"
            "Bash(git reset:*)"
            "Bash(git restore:*)"
            "Bash(git stash:*)"
            "Bash(git switch:*)"

            "Bash(jj commit:*)"
            "Bash(jj describe:*)"
            "Bash(jj new:*)"
            "Bash(jj edit:*)"
            "Bash(jj squash:*)"
            "Bash(jj bookmark:*)"
            "Bash(jj git push:*)"
            "Bash(jj git fetch:*)"

            "Bash(cp:*)"
            "Bash(mv:*)"
            "Bash(rm:*)"

            "Bash(systemctl disable:*)"
            "Bash(systemctl enable:*)"
            "Bash(systemctl mask:*)"
            "Bash(systemctl reload:*)"
            "Bash(systemctl restart:*)"
            "Bash(systemctl start:*)"
            "Bash(systemctl stop:*)"
            "Bash(systemctl unmask:*)"

            "Bash(curl:*)"
            "Bash(ping:*)"
            "Bash(rsync:*)"
            "Bash(scp:*)"
            "Bash(ssh:*)"
            "Bash(wget:*)"

            "Bash(nixos-rebuild:*)"
            "Bash(nh os:*)"
            "Bash(sudo:*)"

            "Bash(kill:*)"
            "Bash(killall:*)"
            "Bash(pkill:*)"
          ];

          allow = [
            # git
            "Bash(git add:*)"
            "Bash(git status)"
            "Bash(git log:*)"
            "Bash(git diff:*)"
            "Bash(git show:*)"
            "Bash(git branch:*)"
            "Bash(git remote:*)"

            # jj
            "Bash(jj status)"
            "Bash(jj log:*)"
            "Bash(jj diff:*)"
            "Bash(jj show:*)"
            "Bash(jj branch list:*)"

            # nix
            "Bash(nix:*)"

            # mcp servers
            "mcp__nixos__*"
            "mcp__context7__*"

            "Bash(ls:*)"
            "Bash(find:*)"
            "Bash(grep:*)"
            "Bash(rg:*)"
            "Bash(cat:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(mkdir:*)"
            "Bash(chmod:*)"

            "Bash(systemctl list-units:*)"
            "Bash(systemctl list-timers:*)"
            "Bash(systemctl status:*)"
            "Bash(journalctl:*)"
            "Bash(dmesg:*)"
            "Bash(env)"
            "Bash(claude --version)"
            "Bash(nh search:*)"

            "Glob(*)"
            "Grep(*)"
            "LS(*)"
            "Read(*)"
            "Search(*)"
            "Task(*)"
            "TodoWrite(*)"

            # web
            "WebFetch(domain:raw.githubusercontent.com)"
            "WebFetch(domain:github.com)"
          ];

          deny = [
            "Bash(rm -rf /*)"
            "Bash(rm -rf /)"
            "Bash(sudo rm -:*)"
            "Bash(chmod 777 /*)"
            "Bash(chmod -R 777 /*)"
            "Bash(dd if=:*)"
            "Bash(mkfs.:*)"
            "Bash(fdisk -:*)"
            "Bash(format -:*)"
            "Bash(shutdown -:*)"
            "Bash(reboot -:*)"
            "Bash(halt -:*)"
            "Bash(poweroff -:*)"
            "Bash(killall -:*)"
            "Bash(pkill -:*)"
            "Bash(nc -l -:*)"
            "Bash(ncat -l -:*)"
            "Bash(netcat -l -:*)"
            "Bash(rm -rf ~:*)"
            "Bash(rm -rf $HOME:*)"
            "Bash(rm -rf ~/.ssh*)"
            "Bash(rm -rf ~/.config*)"

            "Read(~/.ssh)"
            "Read(./.env)"
            "Read(./secrets/**)"
          ];
        };
      };
    };
  };
}

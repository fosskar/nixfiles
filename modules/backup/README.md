# restic backup module

automated daily backups to hetzner storage box with encryption.

## setup

1. import the backup module in the host's `default.nix`:

   ```nix
   imports = [
     ../../modules/backup
   ];
   ```

2. specify what to backup in the same file:

   ```nix
   services.restic.backups.main = {
     paths = [ "/var/lib/yourapp" "/etc/yourconfig" ];
   };
   ```

3. run `agenix generate` to generate encryption password and ssh key

4. git add those newly generated secrets

5. run `agenix rekey -a`

6. deploy with nixos-rebuild remote

7. get the ssh public key from the generated secret:

   ```bash
   ssh root@yourhost "ssh-keygen -y -f /run/agenix/restic-ssh-privkey"
   ```

8. add the key to storage box:

   ```bash
   echo "SSH_PUB_HERE" | ssh SUBUSER@SUBUSER.your-storagebox.de -p 23 install-ssh-key
   ```

## manual backup

```bash
ssh root@yourhost "systemctl start restic-backups-main.service"
```

OR

```bash
restic -r sftp://SUBUSER@SUBUSER.your-storagebox.de:23/backup/hostname --password-file /run/agenix/restic-encryption-password --option sftp.command='ssh -p 23 -i /run/agenix/restic-ssh-privkey -o IdentitiesOnly=yes SUBUSER@SUBUSER.your-storagebox.de -s sftp' backup /path/to/backup
```

## restore

### list snapshots

```bash
restic -r sftp://SUBUSER@SUBUSER.your-storagebox.de:23/backup/hostname --password-file /run/agenix/restic-encryption-password --option sftp.command='ssh -p 23 -i /run/agenix/restic-ssh-privkey -o IdentitiesOnly=yes SUBUSER@SUBUSER.your-storagebox.de -s sftp' snapshots
```

### latest

```bash
restic -r sftp://SUBUSER@SUBUSER.your-storagebox.de:23/backup/hostname --password-file /run/agenix/restic-encryption-password --option sftp.command='ssh -p 23 -i /run/agenix/restic-ssh-privkey -o IdentitiesOnly=yes SUBUSER@SUBUSER.your-storagebox.de -s sftp' restore latest --target /
```

### specific

```bash
restic -r sftp://SUBUSER@SUBUSER.your-storagebox.de:23/backup/hostname --password-file /run/agenix/restic-encryption-password --option sftp.command='ssh -p 23 -i /run/agenix/restic-ssh-privkey -o IdentitiesOnly=yes SUBUSER@SUBUSER.your-storagebox.de -s sftp' restore SNAPSHOT_ID --target /
```

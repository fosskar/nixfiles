{
  lib,
  ...
}:
let
  # read user list from private nixsecrets repo
  # list of { name = "username"; uid = 3000; }
  fileserverUsers = import ./user-list.nix;

  mkFileServerUser =
    user:
    lib.nameValuePair user.name {
      inherit (user) uid;
      description = "file server user";
      extraGroups = [ "shared" ];
      isNormalUser = true;
      createHome = false; # needs to be false otherwise it overrides groups on userfolders
      home = "/mnt/shares/${user.name}";
      useDefaultShell = false;
      autoSubUidGidRange = false;
      # no system password - authentication via samba TDB only
    };
in
{
  # expose user list for samba.nix and secrets to use
  options.fileserverUsers = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          uid = lib.mkOption { type = lib.types.int; };
        };
      }
    );
    default = [ ];
    description = "list of fileserver users with deterministic UIDs";
  };

  config = {
    inherit fileserverUsers;

    users = {
      groups = {
        # create dedicated shared group for users with shared folder access
        shared = {
          gid = 5000;
        };

        # create storage group for lxc bind mount permissions
        storage_shared = {
          gid = 10000;
        };
      };

      # auto-generate all users from list
      users = builtins.listToAttrs (map mkFileServerUser fileserverUsers) // {
        # storage user for lxc bind mount file ownership
        fileserver = {
          uid = 1104; # container 104 -> uid 1104 -> host 101104;
          group = "storage_shared";
          isSystemUser = true;
        };
      };
    };

    # automatically create user directories and shared directory via tmpfiles
    systemd.tmpfiles.rules = [
      # shared directory accessible by shared group (read+write for group)
      "d /mnt/shares/shared 2775 fileserver shared -"
    ]
    # user directories created via tmpfiles (parent level only, storage_shared can traverse but not list)
    ++ (map (user: "d /mnt/shares/${user.name} 0710 ${user.name} storage_shared -") fileserverUsers);

    # create subdirectories via activation script (tmpfiles.d doesn't handle nested dirs reliably)
    system.activationScripts.createUserShareSubdirs = lib.stringAfter [ "users" "groups" ] ''
      # create shared folder structure first (moved from tmpfiles due to unsafe path transition)
      install -d -m 2775 -o fileserver -g shared /mnt/shares/shared/documents
      install -d -m 2775 -o fileserver -g storage_shared /mnt/shares/shared/documents/consume

      ${lib.concatMapStringsSep "\n" (user: ''
        # create pictures subdirectory (readable by storage_shared)
        install -d -m 0750 -o ${user.name} -g storage_shared /mnt/shares/${user.name}/pictures

        # create documents subdirectory (readable by storage_shared)
        install -d -m 0750 -o ${user.name} -g storage_shared /mnt/shares/${user.name}/documents

        # create documents/consume subdirectory (readable by storage_shared)
        install -d -m 0770 -o ${user.name} -g storage_shared /mnt/shares/shared/documents/consume/${user.name}
      '') fileserverUsers}
    '';
  };
}

{ inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    directories = [ "/var/log" ];
    files = [ "/path/to/file" ];
    users.simon = {
      directories = [
        "Downloads"
        "Pictures"
        "Documents"
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
      files = [

      ];
    };
  };
}

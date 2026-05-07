{ pkgs, ... }:
{
  environment = {
    packages = with pkgs; [
      bat
      btop
      fd
      fish
      git
      jq
      ripgrep
      tmux
      unzip
      wget
      zip
    ];

    etcBackupExtension = ".bak";
  };

  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;

    config = _: {
      home = {
        stateVersion = "24.05";
        sessionVariables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
        };
      };

      programs = {
        fish.enable = true;
        git.enable = true;
        home-manager.enable = true;
        neovim = {
          enable = true;
          defaultEditor = true;
          withPython3 = false;
          withRuby = false;
        };
      };
    };
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "24.05";
  time.timeZone = "Europe/Berlin";
  user.shell = "${pkgs.fish}/bin/fish";
}

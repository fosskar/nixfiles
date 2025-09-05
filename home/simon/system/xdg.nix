{
  config,
  pkgs,
  ...
}:
let

  #browser = [ "firefox.desktop" ];
  browser = [ "zen-twilight.desktop" ];
  chromeBrowser = [ "brave" ];
  zathura = [ "zathura" ];
  fileManager = [ "yazi" ];
  mailer = [ "proton-mail" ];
  editor = [ "zeditor" ];

  associations = {
    "text/html" = browser;
    "text/xml" = browser;
    "text/plain" = editor;
    "application/json" = editor;
    "application/pdf" = zathura;
    "application/xml" = browser;
    "application/xhtml+xml" = browser;
    "application/xhtml_xml" = browser;
    "application/rdf+xml" = browser;
    "application/rss+xml" = browser;
    "application/x-extension-htm" = browser;
    "application/x-extension-html" = browser;
    "application/x-extension-shtml" = browser;
    "application/x-extension-xht" = browser;
    "application/x-extension-xhtml" = browser;
    "application/x-wine-extension-ini" = editor;
    "x-scheme-handler/about" = browser; # open `about:` url with `browser`
    "x-scheme-handler/chrome" = chromeBrowser;
    "x-scheme-handler/ftp" = browser; # open `ftp:` url with `browser`
    "x-scheme-handler/http" = browser;
    "x-scheme-handler/https" = browser;
    #"x-scheme-handler/unknown" = browser;

    "inode/directory" = fileManager;

    "audio/*" = [ "mpv.desktop" ];
    "video/*" = [ "mpv.desktop" ];
    "image/*" = [ "imv.desktop" ];
    "image/gif" = [ "imv.desktop" ];
    "image/jpeg" = [ "imv.desktop" ];
    "image/png" = [ "imv.desktop" ];
    "image/webp" = [ "imv.desktop" ];

    "x-scheme-handler/spotify" = [ "spotify.desktop" ];
    "x-scheme-handler/discord" = [ "WebCord.desktop" ];
    "x-scheme-handler/mailto" = mailer;
  };
in
{
  xdg = {
    enable = true;
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";

    userDirs = {
      enable = true;
      createDirectories = true;

      # disable unused home dirs
      download = "${config.home.homeDirectory}/downloads";
      documents = "${config.home.homeDirectory}/documents";
      pictures = "${config.home.homeDirectory}/pictures";
      videos = null;
      desktop = null;
      publicShare = null;
      music = null;
      templates = null;

      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/screenshots";
      };
    };

    mimeApps = {
      enable = true;
      #associations.added = associations;
      defaultApplications = associations;
    };
    ## already set in nixos
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config = {
        common = {
          default = [
            "gtk"
          ];
        };
        hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };
      };
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}

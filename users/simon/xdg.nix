{
  config,
  ...
}:
let
  # only enable portal in home-manager if not already managed by nixos

  browser = [ "zen-beta.desktop" ];
  pdf = [ "org.pwmt.zathura.desktop" ];
  fileManager = [ "org.gnome.Nautilus.desktop" ];
  editor = [ "dev.zed.Zed-Nightly.desktop" ];
  imageViewer = [ "imv.desktop" ];
  mediaPlayer = [ "mpv.desktop" ];

  associations = {
    "text/html" = browser;
    "text/xml" = browser;
    "text/plain" = editor;
    "application/json" = editor;
    "application/pdf" = pdf;
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
    "x-scheme-handler/chrome" = browser;
    "x-scheme-handler/ftp" = browser; # open `ftp:` url with `browser`
    "x-scheme-handler/http" = browser;
    "x-scheme-handler/https" = browser;
    "x-scheme-handler/mailto" = browser;
    "x-scheme-handler/unknown" = browser;

    "inode/directory" = fileManager;

    "audio/*" = mediaPlayer;
    "video/*" = mediaPlayer;
    "image/*" = imageViewer;
    "image/gif" = imageViewer;
    "image/jpeg" = imageViewer;
    "image/png" = imageViewer;
    "image/webp" = imageViewer;

    "x-scheme-handler/spotify" = [ "spotify.desktop" ];
    "x-scheme-handler/discord" = [ "WebCord.desktop" ];
  };
in
{
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      setSessionVariables = true;
      createDirectories = true;

      # disable unused home dirs
      videos = null;
      desktop = null;
      publicShare = null;
      music = null;
      templates = null;

      extraConfig = {
        SCREENSHOTS = "${config.xdg.userDirs.pictures}/screenshots";
      };
    };

    mimeApps = {
      enable = true;
      #associations.added = associations;
      defaultApplications = associations;
    };
  };
}

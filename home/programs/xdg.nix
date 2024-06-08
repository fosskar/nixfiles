{
  config,
  pkgs,
  ...
}: let
  browser = ["firefox"];
  editor = ["codium"];
  imageViewer = ["org.gnome.Loupe"];
  videoPlayer = ["mpv"];
  audioPlayer = ["mpv"];

  xdgAssociations = type: program: list:
    builtins.listToAttrs (map (e: {
        name = "${type}/${e}";
        value = program;
      })
      list);

  image = xdgAssociations "image" imageViewer ["png" "jpeg" "gif"];
  video = xdgAssociations "video" videoPlayer ["mp4" "avi" "mkv"];
  audio = xdgAssociations "audio" audioPlayer ["mp3" "flac" "wav" "aac"];
  browserTypes =
    (xdgAssociations "application" browser [
      "json"
      "x-extension-htm"
      "x-extension-html"
      "x-extension-shtml"
      "x-extension-xht"
      "x-extension-xhtml"
      "xhtml+xml"
    ])
    // (xdgAssociations "x-scheme-handler" browser [
      "about"
      "ftp"
      "http"
      "https"
      "unknown"
    ]);

  # XDG MIME types
  associations = builtins.mapAttrs (_: v: (map (e: "${e}.desktop") v)) ({
      "application/x-shellscript" = editor;
      "inode/directory" = ["yazi"];
      "application/pdf" = ["org.pwmt.zathura-pdf-mupdf"];
      "x-scheme-handler/chrome" = ["chromium-browsee"];
      "x-scheme-handler/spotify" = ["spotify"];
      "image/svg" = editor;
      "image/svg+xml" = editor;
      "text/plain" = editor;
      "text/html" = browser;
      "text/x-csrc" = ["codium" "nvim"];
      "text/css" = editor;
    }
    // image
    // video
    // audio
    // browserTypes);
in {
  xdg = {
    enable = true;
    cacheHome = config.home.homeDirectory + "/.local/cache";

    mimeApps = {
      enable = true;
      defaultApplications = associations;
    };

    userDirs = {
      enable = true;
      createDirectories = true;
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
      };
    };
  };
  home.packages = [
    # used by `gio open` and xdp-gtk
    (pkgs.writeShellScriptBin "xdg-terminal-exec" ''
      foot "$@"
    '')
    pkgs.xdg-utils
  ];
}

{
  lib,
  config,
  pkgs,
  ...
}:
{
  # srvos.desktop sets: daemonCPUSchedPolicy = "idle"

  assertions = [
    {
      assertion = config.programs.nh.enable -> config.programs.nh.flake != null;
      message = "programs.nh.flake must be set when nh is enabled";
    }
  ];

  clan.core.vars.generators.nix-access-tokens = {
    files.tokens.secret = true;
    prompts.tokens = {
      description = "nix access-tokens line (e.g. access-tokens = github.com=ghp_...)";
      type = "multiline";
      persist = true;
    };
    script = "cat $prompts/tokens > $out/tokens";
  };

  nix.extraOptions = ''
    !include ${config.clan.core.vars.generators.nix-access-tokens.files.tokens.path}
  '';

  # cross-build for aarch64 (e.g. nix-on-droid)
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # allow running unpatched binaries (editor LSPs, AppImages, etc.)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries =
    with pkgs;
    [
      # core
      acl
      attr
      bzip2
      dbus
      expat
      fuse3
      icu
      libnotify
      libsodium
      libssh
      libunwind
      libusb1
      libuuid
      nspr
      nss
      stdenv.cc.cc
      util-linux
      zlib
      zstd
    ]
    ++ lib.optionals config.hardware.graphics.enable [
      # graphics / desktop
      fontconfig
      freetype
      libxkbcommon
      pango
      mesa
      libdrm
      libglvnd
      libGL
      vulkan-loader
      # audio
      pipewire
      libpulseaudio
      alsa-lib
      # gtk/gdk
      cairo
      gdk-pixbuf
      glib
      gtk3
      atk
      at-spi2-atk
      at-spi2-core
      libappindicator-gtk3
      # x11 compat (electron, etc.)
      xorg.libX11
      xorg.libxcb
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libXScrnSaver
      xorg.libxkbfile
      xorg.libxshmfence
      # misc
      cups
    ];

  # envfs — fuse mount on /usr/bin that resolves shebangs dynamically
  # makes #!/usr/bin/python3, #!/usr/bin/env bash, etc. work for unpatched scripts
  services.envfs.enable = lib.mkDefault true;

  # nh - nix helper for desktop users
  programs.nh = {
    enable = lib.mkDefault true;
    clean = {
      enable = lib.mkDefault true;
      extraArgs = lib.mkDefault "--keep 5 --keep-since 3d";
    };
  };
}

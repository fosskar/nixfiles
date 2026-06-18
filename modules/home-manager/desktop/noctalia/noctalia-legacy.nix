{ inputs, ... }:
{
  flake.modules.homeManager.noctalia-legacy =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.noctalia-legacy.homeModules.default ];

      config =
        let
          t = config.theme;
          lockSecrets = pkgs.writeShellScript "lock-secrets" ''
            ${pkgs.libsecret}/bin/secret-tool lock --collection=kdewallet 2>/dev/null || true
          '';

          noctalia =
            cmd:
            [
              (lib.getExe config.programs.noctalia-shell.package)
              "ipc"
              "call"
            ]
            ++ (lib.splitString " " cmd);

          shellBinds = {
            "Mod+Space" = {
              title = "Toggle Launcher";
              t = "launcher";
              a = "toggle";
            };
            "Mod+B" = {
              title = "Toggle Clipboard";
              t = "launcher";
              a = "clipboard";
            };
            "Mod+X" = {
              title = "Toggle Power Menu";
              t = "sessionMenu";
              a = "toggle";
            };
            "Mod+Shift+L" = {
              title = "Lock Screen";
              t = "lockScreen";
              a = "lock";
            };
            "Mod+N" = {
              title = "Toggle Notifications";
              t = "notifications";
              a = "toggleHistory";
            };
            "Mod+M" = {
              title = "Toggle Control Center";
              t = "controlCenter";
              a = "toggle";
            };
            "XF86AudioRaiseVolume" = {
              locked = true;
              t = "volume";
              a = "increase";
            };
            "XF86AudioLowerVolume" = {
              locked = true;
              t = "volume";
              a = "decrease";
            };
            "XF86AudioMute" = {
              locked = true;
              t = "volume";
              a = "muteOutput";
            };
            "XF86AudioMicMute" = {
              locked = true;
              t = "volume";
              a = "muteInput";
            };
            "XF86MonBrightnessUp" = {
              locked = true;
              t = "brightness";
              a = "increase";
            };
            "XF86MonBrightnessDown" = {
              locked = true;
              t = "brightness";
              a = "decrease";
            };
          };

          shellNiriBinds = lib.mapAttrs (
            _: bind:
            {
              spawn = noctalia "${bind.t} ${bind.a}";
            }
            // lib.optionalAttrs (bind ? title) { _props.hotkey-overlay-title = bind.title; }
            // lib.optionalAttrs (bind.locked or false) { _props.allow-when-locked = true; }
          ) shellBinds;
        in
        {
          wayland.windowManager.niri.settings.binds = shellNiriBinds;

          xdg.configFile."noctalia/colorschemes/grey-teal/grey-teal.json".text = builtins.toJSON {
            dark = {
              mPrimary = t.dark.accent.primary;
              mOnPrimary = t.dark.bg.base;
              mSecondary = t.dark.accent.secondary;
              mOnSecondary = t.dark.bg.base;
              mTertiary = t.dark.accent.tertiary;
              mOnTertiary = t.dark.bg.base;
              mError = t.dark.semantic.error;
              mOnError = t.dark.bg.base;
              mSurface = t.dark.bg.base;
              mOnSurface = t.dark.fg.base;
              mHover = t.dark.accent.primary;
              mOnHover = t.dark.bg.base;
              mSurfaceVariant = t.dark.bg.surface;
              mOnSurfaceVariant = t.dark.fg.muted;
              mOutline = t.dark.fg.dim;
              mShadow = t.dark.bg.base;
              terminal = {
                background = t.dark.bg.base;
                foreground = t.dark.fg.base;
                cursor = t.dark.fg.base;
                cursorText = t.dark.bg.base;
                selectionBackground = t.dark.fg.base;
                selectionForeground = t.dark.bg.base;
                normal = {
                  black = t.ansi.normal.black;
                  red = t.ansi.normal.red;
                  green = t.ansi.normal.green;
                  yellow = t.ansi.normal.yellow;
                  blue = t.ansi.normal.blue;
                  magenta = t.ansi.normal.magenta;
                  cyan = t.ansi.normal.cyan;
                  white = t.ansi.normal.white;
                };
                bright = {
                  black = t.ansi.bright.black;
                  red = t.ansi.bright.red;
                  green = t.ansi.bright.green;
                  yellow = t.ansi.bright.yellow;
                  blue = t.ansi.bright.blue;
                  magenta = t.ansi.bright.magenta;
                  cyan = t.ansi.bright.cyan;
                  white = t.ansi.bright.white;
                };
              };
            };
            light = {
              mPrimary = t.light.accent.primary;
              mOnPrimary = t.light.bg.base;
              mSecondary = t.light.accent.secondary;
              mOnSecondary = t.light.bg.base;
              mTertiary = t.light.accent.tertiary;
              mOnTertiary = t.light.bg.base;
              mError = t.light.semantic.error;
              mOnError = t.light.bg.base;
              mSurface = t.light.bg.base;
              mOnSurface = t.light.fg.base;
              mHover = t.light.accent.primary;
              mOnHover = t.light.bg.base;
              mSurfaceVariant = t.light.bg.surface;
              mOnSurfaceVariant = t.light.fg.muted;
              mOutline = t.light.fg.dim;
              mShadow = t.light.bg.overlay;
              terminal = {
                background = t.light.bg.base;
                foreground = t.light.fg.base;
                cursor = t.light.fg.base;
                cursorText = t.light.bg.base;
                selectionBackground = t.light.fg.base;
                selectionForeground = t.light.bg.base;
                normal = {
                  black = t.light.bg.base;
                  red = t.ansi.normal.red;
                  green = t.ansi.normal.green;
                  yellow = t.ansi.normal.yellow;
                  blue = t.ansi.normal.blue;
                  magenta = t.ansi.normal.magenta;
                  cyan = t.ansi.normal.cyan;
                  white = t.light.fg.base;
                };
                bright = {
                  black = t.light.bg.overlay;
                  red = t.ansi.bright.red;
                  green = t.ansi.bright.green;
                  yellow = t.ansi.bright.yellow;
                  blue = t.ansi.bright.blue;
                  magenta = t.ansi.bright.magenta;
                  cyan = t.ansi.bright.cyan;
                  white = t.dark.bg.elevated;
                };
              };
            };
          };

          # upstream cfg.systemd.enable is deprecated + breaks eval; inline original unit
          systemd.user.services.noctalia-shell = lib.mkIf config.programs.noctalia-shell.enable (
            let
              cfg = config.programs.noctalia-shell;
            in
            {
              Unit = {
                Description = "Noctalia Shell - Wayland desktop shell";
                Documentation = "https://docs.noctalia.dev";
                PartOf = [ config.wayland.systemd.target ];
                After = [ config.wayland.systemd.target ];
                X-Restart-Triggers =
                  lib.optional (cfg.settings != { }) "${config.xdg.configFile."noctalia/settings.json".source}"
                  ++ lib.optional (cfg.colors != { }) "${config.xdg.configFile."noctalia/colors.json".source}"
                  ++ lib.optional (cfg.plugins != { }) "${config.xdg.configFile."noctalia/plugins.json".source}"
                  ++ lib.optional (
                    cfg.user-templates != { }
                  ) "${config.xdg.configFile."noctalia/user-templates.toml".source}"
                  ++ lib.mapAttrsToList (
                    name: _: "${config.xdg.configFile."noctalia/plugins/${name}/settings.json".source}"
                  ) cfg.pluginSettings;
              };
              Service = {
                ExecStart = lib.getExe cfg.package;
                Restart = "on-failure";
              };
              Install.WantedBy = [ config.wayland.systemd.target ];
            }
          );

          programs.noctalia-shell = {
            plugins = {
              sources = [
                {
                  enabled = true;
                  name = "Official Noctalia Plugins";
                  url = "https://github.com/noctalia-dev/noctalia-plugins";
                }
                {
                  enabled = true;
                  name = "Mic92 s Noctalia Plugins";
                  url = "https://github.com/Mic92/noctalia-plugins";
                }
              ];
              states = {
                netbird = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                polkit-agent = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                keybind-cheatsheet = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                kagi-quick-search = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                mirror-mirror = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                privacy-indicator = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };

                # mic92 plugins need the source hash prefix to match on-disk folder names
                "c4d277:display-config" = {
                  enabled = true;
                  sourceUrl = "https://github.com/Mic92/noctalia-plugins";
                };
              };
              version = 2;
            };

            enable = lib.mkDefault true;

            settings = {
              colorSchemes = {
                predefinedScheme = "grey-teal";
                darkMode = true;
              };
              appLauncher = {
                terminalCommand = "ghostty -e";
              };

              templates = {
                enableUserTheming = true;
                activeTemplates = [
                  {
                    id = "btop";
                    enabled = true;
                  }
                  {
                    id = "gtk";
                    enabled = true;
                  }
                  {
                    id = "yazi";
                    enabled = true;
                  }
                  {
                    id = "zathura";
                    enabled = true;
                  }
                  {
                    id = "zed";
                    enabled = true;
                  }
                ];
              };

              ui = {
                panelBackgroundOpacity = 0.7;
                translucentWidgets = true;
              };

              bar = {
                backgroundOpacity = 0.7;
                showCapsule = false;
                widgets = {
                  center = [
                    {
                      id = "Clock";
                      formatHorizontal = "HH:mm\\ndd.MM.yy";
                    }
                    {
                      id = "plugin:privacy-indicator";
                      hideInactive = true;
                      removeMargins = true;
                      activeColor = "error";
                    }
                  ];
                  left = [
                    {
                      id = "ControlCenter";
                      useDistroLogo = true;
                    }
                    {
                      id = "Workspace";
                      hideUnoccupied = true;
                      labelMode = "Name";
                    }
                    {
                      id = "SystemMonitor";
                    }
                    {
                      id = "plugin:c4d277:display-config";
                    }
                    {
                      id = "plugin:mirror-mirror";
                    }
                  ];
                  right = [
                    {
                      id = "Tray";
                      drawerEnabled = false;
                      hidePassive = true;
                    }
                    {
                      id = "Microphone";
                    }
                    {
                      id = "Volume";
                    }
                    {
                      id = "plugin:netbird";
                    }
                    {
                      id = "VPN";
                    }
                    {
                      id = "Network";
                    }
                    {
                      id = "Bluetooth";
                    }
                    {
                      id = "Battery";
                    }
                    {
                      id = "NoctaliaPerformance";
                    }
                    {
                      id = "PowerProfile";
                    }
                    {
                      id = "KeepAwake";
                    }
                    {
                      id = "NotificationHistory";
                    }
                    {
                      id = "SessionMenu";
                    }
                  ];
                };
              };

              dock = {
                enabled = false;
              };

              idle = {
                enabled = true;
                screenOffTimeout = 300;
                lockTimeout = 1800;
                suspendTimeout = 3600;
              };

              general = {
                autoStartAuth = true;
                allowPasswordWithFprintd = osConfig.services.fprintd.enable or false;
                lockOnSuspend = true;
                showScreenCorners = true;
                forceBlackScreenCorners = true;
                compactLockScreen = true;
                lockScreenBlur = 0.5;
              };

              hooks = {
                enabled = true;
                screenLock = toString lockSecrets;
                screenUnlock = "kwallet-tpm-unlock $HOME/.config/kwallet-tpm/password.cred";
              };

              location = {
                name = "Hamburg";
              };

              notifications = {
                density = "compact";
              };

              osd.location = "right";

              wallpaper = {
                enabled = true;
                useWallhaven = true;
                automationEnabled = false;
                overviewEnabled = true;
                overviewBlur = 0.4;
              };

              sessionMenu = {
                countdownDuration = 1000;
                largeButtonsLayout = "grid";
              };
            };
          };
        };
    };
}

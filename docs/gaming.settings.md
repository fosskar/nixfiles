# Steam Gaming

## CS2

### Launch Options

```shell
MESA_VK_WSI_PRESENT_MODE=immediate RADV_DEBUG=nogpl MANGOHUD=1 gamescope -w 1920 -h 1080 -W 3440 -H 1440 -r 165 -f -e --immediate-flips -F fsr -- gamemoderun %command% -vulkan -nojoy
```

#### Options explained

`MESA_VK_WSI_PRESENT_MODE=immediate`    ...

`RADV_DEBUG=nogpl`    makes compiling shaders new everytime when startet with this

`MANGOHUD=1`    activated mangohud overlay

`gamescope -w 1920 -h 1080 -W 3440 -H 1440 -r 165 -f -e --immediate-flips -F fsr --`   starts the game with gamescope and given params

`gamemoderun`   starts the game with gamemode

`%command%`   everything before this got executed before the game starts. commands after that are game specific commands

`-vulkan -nojoy`    cs2 specific commands


# Hyprland change resolution

```shell
hyprctl keyword monitor "DP-1,3440x1440@165,0x0,1"
``````

```shell
hyprctl keyword monitor "DP-1,2560x1440@165,0x0,1"
```

{
  flake.modules.nixos.haGreen =
    {
      config,
      pkgs,
      inputs,
      ...
    }:
    let
      patches = "${inputs.haos}/buildroot-external/board/nabucasa/green/patches/linux";
      inherit (config.boot.kernelPackages) kernel;

      # mainline has no green board; build only its dtb from the haos dts patches
      dtbs = pkgs.stdenv.mkDerivation {
        pname = "ha-green-dtbs";
        inherit (kernel) version src;
        nativeBuildInputs = [ pkgs.dtc ];
        unpackPhase = ''
          tar -xf $src --strip-components=1 --wildcards '*/arch/arm64/boot/dts/rockchip' '*/include/dt-bindings'
        '';
        patches = [
          "${patches}/0001-arm64-dts-rockchip-Add-NabuCasa-Green-board.patch"
          "${patches}/0003-arch-arm64-dts-green-Remove-spiflash-partitions.patch"
          "${patches}/0005-green-emmc-use-HS200-mode.patch"
          "${patches}/0006-arch-arm64-dts-green-Improve-LED-representation.patch"
        ];
        buildPhase = ''
          $CC -E -nostdinc -Iinclude -Iarch/arm64/boot/dts/rockchip -undef -D__DTS__ -x assembler-with-cpp \
            arch/arm64/boot/dts/rockchip/rk3566-ha-green.dts \
            | dtc -I dts -O dtb -@ -o rk3566-ha-green.dtb
        '';
        installPhase = ''
          install -D rk3566-ha-green.dtb $out/rockchip/rk3566-ha-green.dtb
        '';
      };

      # the power key is low-active; the stock driver reports press and release reversed
      rk805-pwrkey = config.boot.kernelPackages.callPackage (
        { stdenv, kernelModuleMakeFlags }:
        stdenv.mkDerivation {
          pname = "rk805-pwrkey";
          inherit (kernel) version src;
          unpackPhase = ''
            tar -xf $src --strip-components=1 --wildcards '*/drivers/input/misc/rk805-pwrkey.c'
          '';
          patches = [ "${patches}/0004-Input-rk805-pwrkey-reverse-polarity-of-pwrkey.patch" ];
          nativeBuildInputs = kernel.moduleBuildDependencies;
          buildPhase = ''
            echo 'obj-m := rk805-pwrkey.o' > drivers/input/misc/Kbuild
            make ${toString kernelModuleMakeFlags} \
              -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
              M=$PWD/drivers/input/misc modules
          '';
          # depmod prefers updates/ over the stock module of the same name
          installPhase = ''
            install -D drivers/input/misc/rk805-pwrkey.ko \
              $out/lib/modules/${kernel.modDirVersion}/updates/rk805-pwrkey.ko
          '';
        }
      ) { };
    in
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      # haos's u-boot boots extlinux.conf; it has no efi loader
      boot.loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };

      hardware.deviceTree = {
        dtbSource = dtbs;
        name = "rockchip/rk3566-ha-green.dtb";
      };

      boot.extraModulePackages = [ rk805-pwrkey ];

      # the battery-backed rtc is the pcf8563; haos disables the pmic rtc so it never becomes rtc0
      boot.blacklistedKernelModules = [ "rtc_rk808" ];

      # from haos board/nabucasa/green/cmdline.txt; the last console (hdmi) becomes /dev/console
      boot.kernelParams = [
        "console=ttyS2,1500000n8"
        "console=tty0"
      ];
    };
}

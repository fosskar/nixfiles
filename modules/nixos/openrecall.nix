{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      ps.flask
      ps.numpy
      ps.pillow
      ps.pytorch
      ps.torchvision
      ps.shapely
      ps.h5py
      ps.rapidfuzz
      ps.psutil
      ps.opencv4
      ps.anyascii
      ps.pyclipper
      (ps.buildPythonPackage rec {
        pname = "sentence-transformers";
        version = "3.0.0";
        src = ps.fetchPypi {
          inherit pname version;
          #sha256 = lib.fakeSha256;
          hash = "sha256-bre5AIzydCiBH6M66zXzM024Hj98wt1J7HxuWpSznxI=";
        };
      })
      (ps.buildPythonPackage rec {
        pname = "mss";
        version = "9.0.1";
        src = ps.fetchPypi {
          inherit pname version;
          hash = "sha256-bre5AIzydCiBH6M66zXzM024Hj98wt1J7HxuWpSznxI=";
        };
        buildInputs = with pkgs; [
          pkgs.xorg.libX11
          pkgs.xorg.libXrandr
        ];
        postPatch = ''
          sed -i 's|find_library("X11")|"${pkgs.xorg.libX11}/lib/libX11.so"|' src/mss/linux.py
          sed -i 's|find_library("Xrandr")|"${pkgs.xorg.libXrandr}/lib/libXrandr.so"|' src/mss/linux.py
        '';
        doCheck = false;
        pythonImportsCheck = ["mss"];
      })
      (ps.buildPythonPackage rec {
        pname = "doctr";
        version = "latest";
        src = pkgs.fetchFromGitHub {
          owner = "koenvaneijk";
          repo = "doctr";
          rev = "main";
          hash = "sha256-4TcAYp80tSyy7JZTn/823dRdQOSn6olJOWjH/mkROYE=";
        };
        doCheck = false;
      })
    ]);

  openrecall = pkgs.stdenv.mkDerivation rec {
    pname = "openrecall";
    version = "latest";

    src = pkgs.fetchFromGitHub {
      owner = "openrecall";
      repo = "openrecall";
      rev = "main";
      hash = "sha256-ZxorQXGpcCr7oYK3ezaHtGUl1DO/ZLqeZ4d/0yQ6zcg=";
    };

    nativeBuildInputs = [
      pkgs.python3Packages.setuptools
      pkgs.python3Packages.pip
      pkgs.python3Packages.virtualenv
    ];
    buildInputs = [pythonEnv];

    installPhase = ''
      mkdir -p $out
      ${pkgs.python3Packages.virtualenv}/bin/virtualenv $out/venv
      source $out/venv/bin/activate
      pip install --upgrade --no-cache-dir $src
      # Logging installed packages for debugging
      pip list > $out/pip-list.txt
      # Logging environment variables for debugging
      env > $out/env-vars.txt
    '';

    doCheck = false;
    #checkPhase = ''
    #  source $out/venv/bin/activate
    #  ${pkgs.python3}/bin/pytest
    #'';

    meta = with lib; {
      description = "openrecall";
      license = licenses.mit;
      maintainers = with maintainers; [simonoscr];
    };
  };
in {
  options.services.openrecall = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the OpenRecall service.";
    };
  };

  config = mkIf config.services.openrecall.enable {
    systemd.services.openrecall = {
      description = "OpenRecall Service";

      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = ''
          ${pkgs.xvfb-run}/bin/xvfb-run -s "-screen 0 3440x1440x24" ${openrecall}/venv/bin/python3 -m openrecall.app
        '';
        Restart = "always";
        User = "openrecall";
        Group = "openrecall";
        Environment = [
          "HF_HOME=/var/lib/openrecall/.cache/huggingface"
          "XDG_CACHE_HOME=/var/lib/openrecall/.cache"
          "HOME=/var/lib/openrecall"
          "DISPLAY=:99"
        ];
      };
    };

    users = {
      groups.openrecall = {};
      users.openrecall = {
        isSystemUser = true;
        group = "openrecall";
        home = "/var/lib/openrecall";
        createHome = true;
      };
    };
    systemd.tmpfiles.rules = [
      "d /var/lib/openrecall/.cache 0755 openrecall openrecall -"
      "d /var/lib/openrecall/.cache/huggingface 0755 openrecall openrecall -"
    ];

    networking.firewall.allowedTCPPorts = [8082];
  };
}

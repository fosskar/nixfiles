# FIXME: drop once https://redirect.github.com/NixOS/nixpkgs/pull/575392 reaches nixos-unstable;
# urllib3-future socks tests time out (~1.6 h) against python-socks v3 and hide a niquests failure
_:
_: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_: pyPrev: {
      urllib3-future = pyPrev.urllib3-future.overridePythonAttrs { doCheck = false; };
      niquests = pyPrev.niquests.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [ "test_use_proxy_from_environment" ];
      });
    })
  ];
}

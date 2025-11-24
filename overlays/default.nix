{ ... }:
{
  default = final: _prev: {
    pulse-host-agent = final.callPackage ../packages/pulse-host-agent { };
  };
}

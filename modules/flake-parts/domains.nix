{
  # fleet-wide DNS domains. pure metadata; reachable everywhere via
  # self/flake-self (modules) and config.flake.domains (flake-parts/clan).
  flake.domains = {
    local = "nx3.eu";
    public = "fosskar.eu";
  };
}

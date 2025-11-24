# pulse-host-agent nixos module

nixos module for running pulse-host-agent as a systemd service.

## usage

### basic configuration

```nix
{
  imports = [
    ../../../../modules/pulse-host-agent
  ];

  services.pulse-host-agent = {
    enable = true;
    url = "http://10.0.0.97:7655";
    tokenFile = "/run/secrets/pulse-token";
    interval = "30s";
  };
}
```

### with agenix secrets

```nix
{
  imports = [
    ../../../../modules/pulse-host-agent
    ./secrets.nix
  ];

  age.secrets.pulse-token = {
    file = ../../secrets/pulse-token.age;
    mode = "400";
  };

  services.pulse-host-agent = {
    enable = true;
    url = "https://pulse.example.com";
    tokenFile = config.age.secrets.pulse-token.path;
    interval = "1m";
    tags = [ "production" "lxc" ];
  };
}
```

### full configuration

```nix
services.pulse-host-agent = {
  enable = true;
  url = "https://pulse.example.com";
  tokenFile = "/run/secrets/pulse-token";
  interval = "30s";
  hostname = "custom-hostname"; # override system hostname
  tags = [ "production" "monitoring" "lxc" ];
  insecure = false; # skip tls verification (testing only)
};
```

## options

- `enable` - enable the pulse-host-agent service
- `package` - package to use (default: pkgs.pulse-host-agent)
- `url` - pulse server url (required)
- `tokenFile` - path to file containing api token with host-agent:report scope (required)
- `interval` - reporting interval (default: "30s", examples: "1m", "5m")
- `hostname` - override hostname reported to pulse (optional)
- `tags` - list of tags to apply to this host (default: [])
- `insecure` - skip tls certificate verification (default: false)

## requirements

- pulse server version >= 4.26.0
- api token with `host-agent:report` scope

## systemd service

the module creates a systemd service with:

- automatic restart on failure (5s delay)
- proper security hardening
- runs as root (required for full system metrics)
- waits for network-online before starting

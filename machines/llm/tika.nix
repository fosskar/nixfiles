_: {
  services.tika = {
    enable = true;
    enableOcr = true;
    listenAddress = "127.0.0.1";
    openFirewall = false;
    port = 9998;
  };
}

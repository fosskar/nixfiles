_: {
  services.n8n = {
    enable = true;
    openFirewall = false;
    environment.N8N_PORT = 5679;
  };
}

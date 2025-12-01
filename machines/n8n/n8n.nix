_: {
  services.n8n = {
    enable = true;
    openFirewall = true;
    environment.N8N_PORT = 5679;
  };
}

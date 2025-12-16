_: {
  services.n8n = {
    # temporarily disabled - hash mismatch in nixpkgs
    # see: https://github.com/NixOS/nixpkgs/issues (search n8n hash)
    enable = false;
    openFirewall = false;
    environment.N8N_PORT = 5679;
  };
}

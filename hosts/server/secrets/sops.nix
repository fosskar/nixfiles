{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    validateSopsFiles = false;
    defaultSopsFile = "/root/code/nixsecrets/secrets/server/secrets.yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      c3NoLXB1Yi1rZXk = {
        mode = "0600";
        owner = "root";
        path = "/root/.ssh/authorized_keys";
      };
      c3NoLXByaXZhdGUta2V5 = {
        mode = "0600";
        owner = "root";
        path = "/root/.ssh/id_ed25519";
      };
      V0lGSQ = {
        path = "/etc/wpa_supplicant.conf";
      };
      Z2l0bGFiLXJ1bm5lci1yZWdpc3RyYXRpb24 = { };
    };
  };
}

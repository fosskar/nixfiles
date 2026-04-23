{
  flake.modules.nixos.fprint =
    { pkgs, ... }:
    {
      services.fprintd.enable = true;

      # fprint AFTER password (order 13000 > unix at 12900)
      # flow: yubikey → password → fprint
      security.pam.services =
        let
          fprintService = _: {
            fprintAuth = true;
            rules.auth.fprintd = {
              order = 13000;
              control = "sufficient";
              modulePath = "${pkgs.fprintd}/lib/security/pam_fprintd.so";
            };
          };
        in
        {
          login = fprintService null;
          greetd = fprintService null;
        };

      preservation.preserveAt."/persist".directories = [ "/var/lib/fprint" ];
    };
}

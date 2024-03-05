{
  config,
  pkgs,
  lib,
  ...
}: {
  services.openldap = {
    enable = true;

    /*
    enable plain connections only
    */
    urlList = ["ldap:///"];

    settings = {
      attrs = {
        olcLogLevel = "conns config";
      };

      children = {
        "cn=schema".includes = [
          "${pkgs.openldap}/etc/schema/core.ldif"
          "${pkgs.openldap}/etc/schema/cosine.ldif"
          "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
        ];

        "olcDatabase={1}mdb".attrs = {
          objectClass = ["olcDatabaseConfig" "olcMdbConfig"];
          olcDatabase = "{1}mdb";
          olcDbDirectory = "/var/lib/openldap/data";
          olcRootPW.path = pkgs.writeText "olcRootPW" "123"; # FIXME dont use writeText and also use sops secret here
          olcRootDN = "cn=admin,dc=oscar";
          olcSuffix = "dc=oscar";
          olcAccess = [
            ''              {0}to attrs=userPassword
                              by self write
                              by anonymous auth
                              by * none''

            ''              {1}to *
                              by * read''
          ];
        };
        "cn={1}grafana,cn=schema".attrs = {
          cn = "{1}grafana";
          objectClass = "olcSchemaConfig";
          olcObjectClasses = [
            ''              (1.3.6.1.4.1.28293.1.2.5 NAME 'grafana'
                           SUP uidObject AUXILIARY
                           DESC 'Added to an account to allow grafana access'
                           MUST (mail))
            ''
          ];
        };
        #"cn={1}openssh,cn=schema".attrs = {
        #  cn = "{1}openssh";
        #  objectClass = "olcSchemaConfig";
        #  olcAttributeTypes = [
        #    ''              (1.3.6.1.4.1.24552.500.1.1.1.13
        #                   NAME 'sshPublicKey'
        #                   DESC 'MANDATORY: OpenSSH Public key'
        #                   EQUALITY octetStringMatch
        #                   SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )''
        #  ];
        #  olcObjectClasses = [
        #    ''              (1.3.6.1.4.1.24552.500.1.1.2.0
        #                   NAME 'ldapPublicKey'
        #                   SUP top AUXILIARY
        #                   DESC 'MANDATORY: OpenSSH LPK objectclass'
        #                   MUST ( sshPublicKey $ uid ))
        #    ''
        #  ];
        #};
        "cn={1}prometheus,cn=schema".attrs = {
          cn = "{1}prometheus";
          objectClass = "olcSchemaConfig";
          olcObjectClasses = [
            ''              (1.3.6.1.4.1.28296.1.2.4
                           NAME 'prometheus'
                           SUP uidObject AUXILIARY
                           DESC 'Added to an account to allow prometheus access'
                           MUST (mail))
            ''
          ];
        };
        "cn={1}loki,cn=schema".attrs = {
          cn = "{1}loki";
          objectClass = "olcSchemaConfig";
          olcObjectClasses = [
            ''              (1.3.6.1.4.1.28299.1.2.4
                           NAME 'loki'
                           SUP uidObject AUXILIARY
                           DESC 'Added to an account to allow loki access'
                           MUST (mail))
            ''
          ];
        };
      };
    };
  };
}

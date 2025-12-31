_: {
  services.davmail = {
    enable = true;
    imitateOutlook = true;
    settings = {
      "davmail.allowRemote" = false;
      "davmail.bindAddress" = "127.0.0.1";
      "davmail.url" = "https://exchange-cas.mecom.de/ews/exchange.asmx";

      # Don't use SSL (between email client and davmail)
      "davmail.ssl.nosecurecaldav" = false;
      "davmail.ssl.nosecureimap" = false;
      "davmail.ssl.nosecureldap" = false;
      "davmail.ssl.nosecuresmtp" = false;

      # protocol ports
      "davmail.caldavPort" = 1180;
      "davmail.smtpPort" = 1025;
      "davmail.popPort" = 1110;
      "davmail.imapPort" = 1143;
      "davmail.ldapPort" = 1389;

      # exchange specific settings
      "davmail.mode" = "EWS";
      "davmail.smtpSaveInSent" = true;
      # Delete messages immediately on IMAP STORE \Deleted flag
      "davmail.imapAutoExpunge" = true;
      "davmail.caldavAutoSchedule" = true;
      "davmail.folderSizeLimit" = 1000;
      "davmail.caldavPastDelay" = 180;
      "davmail.keepDelay" = 30;
      "davmail.enableEtags" = true;
      "davmail.forceActiveSyncUpdate" = false;

      # Run davmail in server mode
      "davmail.server" = true;
      "davmail.enableKeepAlive" = true;

      # logging
      "log4j.logger.rootLogger" = "WARN";
      "log4j.logger.davmail" = "WARN";
      "log4j.logger.httpclient.wire" = "WARN";
      "log4j.logger.org.apache.commons.httpclient" = "WARN";
    };
  };
}

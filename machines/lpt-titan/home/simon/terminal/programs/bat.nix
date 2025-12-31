{
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      style = "numbers,changes,header";
      pager = "less -FR";
    };
    themes = {
      ansi-custom = {
        src = builtins.toFile "ansi-custom.tmTheme" ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>name</key>
            <string>Ansi Custom</string>
            <key>settings</key>
            <array>
              <dict>
                <key>settings</key>
                <dict>
                  <key>background</key>
                  <string>#171717</string>
                  <key>foreground</key>
                  <string>#eeeeee</string>
                  <key>caret</key>
                  <string>#a3a3a3</string>
                  <key>selection</key>
                  <string>#a3a3a3</string>
                  <key>selectionForeground</key>
                  <string>#171717</string>
                </dict>
              </dict>
            </array>
          </dict>
          </plist>
        '';
      };
    };
  };
}

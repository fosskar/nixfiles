{ pkgs, ... }:
let
  niri-dynamic-float = pkgs.writeScript "niri-dynamic-float" ''
    #!${pkgs.python3}/bin/python
    """
    dynamic open-float for windows that set title/app-id late.
    based on https://gist.github.com/DerEchteJoghurt/9cabbcf8eb7b4af25e4519feda302cb2
    """

    from dataclasses import dataclass, field
    import json
    import os
    import re
    from socket import AF_UNIX, SHUT_WR, socket


    @dataclass(kw_only=True)
    class Match:
        title: str | None = None
        app_id: str | None = None

        def matches(self, window):
            if self.title is None and self.app_id is None:
                return False
            matched = True
            if self.title is not None and window["title"] is not None:
                matched &= re.search(self.title, window["title"]) is not None
            if self.app_id is not None and window["app_id"] is not None:
                matched &= re.search(self.app_id, window["app_id"]) is not None
            return matched


    @dataclass
    class Rule:
        match: list[Match] = field(default_factory=list)
        exclude: list[Match] = field(default_factory=list)
        width: int = 0
        height: int = 0
        centered: bool = False

        def matches(self, window):
            if len(self.match) > 0 and not any(m.matches(window) for m in self.match):
                return False
            if any(m.matches(window) for m in self.exclude):
                return False
            return True


    RULES = [
        Rule([Match(title=".*Bitwarden.*", app_id="^zen-beta$")],
             width=500, height=800, centered=True),
        Rule([Match(title=".*Bitwarden.*", app_id="^firefox$")],
             width=500, height=800, centered=True),
        Rule([Match(title="^Extension:", app_id="^zen-beta$|^firefox$|^brave$")],
             centered=True),
    ]


    niri_socket = socket(AF_UNIX)
    niri_socket.connect(os.environ["NIRI_SOCKET"])
    file = niri_socket.makefile("rw")

    _ = file.write('"EventStream"')
    file.flush()
    niri_socket.shutdown(SHUT_WR)

    windows = {}


    def send(request):
        with socket(AF_UNIX) as s:
            s.connect(os.environ["NIRI_SOCKET"])
            f = s.makefile("rw")
            _ = f.write(json.dumps(request))
            f.flush()


    def float_window(wid):
        send({"Action": {"MoveWindowToFloating": {"id": wid}}})


    def set_height(wid, height):
        send({"Action": {"SetWindowHeight": {"id": wid, "change": {"SetFixed": height}}}})


    def set_width(wid, width):
        send({"Action": {"SetWindowWidth": {"id": wid, "change": {"SetFixed": width}}}})


    def set_centered(wid, width, height):
        send({"Action": {"MoveFloatingWindow": {"id": wid, "x": {"SetProportion": 50.0}, "y": {"SetProportion": 50.0}}}})
        send({"Action": {"MoveFloatingWindow": {"id": wid, "x": {"AdjustFixed": -(width / 2)}, "y": {"AdjustFixed": -(height / 2)}}}})


    def update_matched(win):
        win["matched"] = False
        if existing := windows.get(win["id"]):
            win["matched"] = existing["matched"]

        matched_before = win["matched"]
        matched_rule = None
        for r in RULES:
            if r.matches(win):
                win["matched"] = True
                matched_rule = r
                break

        if win["matched"] and not matched_before and matched_rule:
            print(f"floating title='{win['title']}', app_id='{win['app_id']}'")
            float_window(win["id"])
            if matched_rule.height != 0:
                set_height(win["id"], matched_rule.height)
            if matched_rule.width != 0:
                set_width(win["id"], matched_rule.width)
            if matched_rule.centered:
                set_centered(win["id"], matched_rule.width, matched_rule.height)


    for line in file:
        event = json.loads(line)

        if changed := event.get("WindowsChanged"):
            for win in changed["windows"]:
                update_matched(win)
            windows = {win["id"]: win for win in changed["windows"]}
        elif changed := event.get("WindowOpenedOrChanged"):
            win = changed["window"]
            update_matched(win)
            windows[win["id"]] = win
        elif changed := event.get("WindowClosed"):
            del windows[changed["id"]]
  '';
in
{
  systemd.user.services.niri-dynamic-float = {
    Unit = {
      Description = "niri dynamic float for late title/app-id windows";
      After = [ "niri.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${niri-dynamic-float}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
  };
}

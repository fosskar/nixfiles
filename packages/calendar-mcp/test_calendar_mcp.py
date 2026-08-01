import asyncio
import importlib.util
import os
from datetime import datetime, timezone
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "calendar_mcp", Path(os.environ["CALENDAR_MCP_SOURCE"])
)
calendar_mcp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(calendar_mcp)


class Component(dict):
    def decoded(self, name):
        return self[name]


class Event:
    def __init__(self, uid, summary, start, end):
        self.icalendar_component = Component(
            UID=uid,
            SUMMARY=summary,
            DTSTART=start,
            DTEND=end,
        )
        self.etag = f"etag-{uid}"


class Calendar:
    def __init__(self, name, events):
        self.name = name
        self.events = events
        self.searches = 0

    def get_display_name(self):
        return self.name

    def search(self, **_arguments):
        self.searches += 1
        return self.events


class Principal:
    def __init__(self, calendars):
        self.calendars = calendars

    def get_calendars(self):
        return self.calendars


class Client:
    def __init__(self, calendars):
        self.calendars = calendars

    def __enter__(self):
        return self

    def __exit__(self, *_arguments):
        return None

    def principal(self):
        return Principal(self.calendars)


work = Calendar(
    "Work",
    [
        Event(
            "work-event",
            "Kita Besichtigung",
            datetime(2026, 8, 5, 12, 30, tzinfo=timezone.utc),
            datetime(2026, 8, 5, 13, 30, tzinfo=timezone.utc),
        )
    ],
)
family = Calendar(
    "Family",
    [
        Event(
            "family-event",
            "baby schwimmen",
            datetime(2026, 8, 6, 9, 45),
            datetime(2026, 8, 6, 10, 15),
        )
    ],
)
calendar_mcp._client = lambda: Client([family, work])


events = asyncio.run(calendar_mcp.list_events("2026-08-01", "2026-08-08"))
assert [event["uid"] for event in events] == ["work-event", "family-event"]
assert events[0]["start"] == "2026-08-05T14:30:00+02:00"
assert events[0]["weekday"] == "Wednesday"
assert events[1]["start"] == "2026-08-06T09:45:00+02:00"
assert events[1]["weekday"] == "Thursday"
assert all(event["timezone"] == "Europe/Berlin" for event in events)
assert work.searches == 1
assert family.searches == 1

selected = asyncio.run(
    calendar_mcp.list_events("2026-08-01", "2026-08-08", calendars=["family"])
)
assert [event["uid"] for event in selected] == ["family-event"]
assert work.searches == 1
assert family.searches == 2

matches = asyncio.run(calendar_mcp.search_events("kita", "2026-08-01", "2026-08-08"))
assert [event["uid"] for event in matches] == ["work-event"]

print("calendar aggregation contract passed")

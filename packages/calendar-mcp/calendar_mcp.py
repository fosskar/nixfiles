"""CalDAV calendar tools over MCP stdio, for one account."""

import os
from datetime import date, datetime
from pathlib import Path
from uuid import uuid4
from zoneinfo import ZoneInfo

import anyio
from caldav import DAVClient
from mcp.server.mcpserver import MCPServer

TIMEZONE = ZoneInfo(os.environ.get("CALDAV_TIMEZONE", "Europe/Berlin"))

mcp = MCPServer("calendar")


def _client() -> DAVClient:
    def secret(name: str) -> str:
        return Path(os.environ[name]).read_text().strip()

    return DAVClient(
        url=os.environ["CALDAV_URL"],
        username=secret("CALDAV_USERNAME_FILE"),
        password=secret("CALDAV_PASSWORD_FILE"),
    )


def _name(calendar) -> str:
    return (
        calendar.get_display_name() or str(calendar.url).rstrip("/").rsplit("/", 1)[-1]
    )


def _calendar(client: DAVClient, name: str):
    for calendar in client.principal().get_calendars():
        if _name(calendar).casefold() == name.casefold():
            return calendar
    raise ValueError(f"calendar not found: {name}")


def _when(value: str) -> date | datetime:
    """an ISO date is an all-day value; a naive datetime is in TIMEZONE"""
    if "T" not in value:
        return date.fromisoformat(value)
    parsed = datetime.fromisoformat(value)
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=TIMEZONE)


def _event(component) -> dict:
    def text(key: str) -> str:
        return str(component.get(key, ""))

    def iso(key: str) -> str:
        value = component.get(key)
        return value.dt.isoformat() if value is not None else ""

    return {
        "uid": text("uid"),
        "summary": text("summary"),
        "start": iso("dtstart"),
        "end": iso("dtend"),
        "location": text("location"),
        "description": text("description"),
    }


@mcp.tool()
async def list_calendars() -> list[str]:
    """Names of the calendars this account can read, including shared ones."""

    def run():
        return [_name(c) for c in _client().principal().get_calendars()]

    return await anyio.to_thread.run_sync(run)


@mcp.tool()
async def list_events(calendar: str, start: str, end: str) -> list[dict]:
    """Events in a calendar between start and end (ISO dates or datetimes), recurrences expanded."""

    def run():
        found = _calendar(_client(), calendar).search(
            start=_when(start), end=_when(end), event=True, expand=True
        )
        return [_event(e.icalendar_component) for e in found]

    return await anyio.to_thread.run_sync(run)


@mcp.tool()
async def create_event(
    calendar: str,
    summary: str,
    start: str,
    end: str,
    location: str = "",
    description: str = "",
) -> dict:
    """Create an event. Dates without a time make an all-day event; end is exclusive."""

    def run():
        uid = str(uuid4())
        _calendar(_client(), calendar).save_event(
            uid=uid,
            summary=summary,
            dtstart=_when(start),
            dtend=_when(end),
            location=location or None,
            description=description or None,
        )
        return {"created": uid, "calendar": calendar}

    return await anyio.to_thread.run_sync(run)


@mcp.tool()
async def update_event(
    calendar: str,
    uid: str,
    summary: str | None = None,
    start: str | None = None,
    end: str | None = None,
    location: str | None = None,
    description: str | None = None,
) -> dict:
    """Change the given fields of an event; omitted fields stay as they are."""

    def run():
        event = _calendar(_client(), calendar).get_event_by_uid(uid)
        component = event.icalendar_component
        for key, value in {
            "summary": summary,
            "location": location,
            "description": description,
        }.items():
            if value is not None:
                component.pop(key, None)
                component.add(key, value)
        for key, value in {"dtstart": start, "dtend": end}.items():
            if value is not None:
                component.pop(key, None)
                component.add(key, _when(value))
        event.save()
        return {"updated": uid, "calendar": calendar}

    return await anyio.to_thread.run_sync(run)


@mcp.tool()
async def delete_event(calendar: str, uid: str) -> dict:
    """Delete an event by uid."""

    def run():
        _calendar(_client(), calendar).get_event_by_uid(uid).delete()
        return {"deleted": uid, "calendar": calendar}

    return await anyio.to_thread.run_sync(run)


if __name__ == "__main__":
    mcp.run("stdio")

from __future__ import annotations

import os
from datetime import date, datetime
from pathlib import Path
from typing import Any
from uuid import uuid4
from zoneinfo import ZoneInfo

import anyio
import uvicorn
from caldav import DAVClient
from mcp.server.fastmcp import FastMCP


class BearerAuth:
    def __init__(self, app: Any, token: str) -> None:
        self.app = app
        self.authorization = f"Bearer {token}".encode()

    async def __call__(self, scope: dict[str, Any], receive: Any, send: Any) -> None:
        if scope["type"] == "http":
            headers = dict(scope.get("headers", []))
            if headers.get(b"authorization") != self.authorization:
                await send(
                    {
                        "type": "http.response.start",
                        "status": 401,
                        "headers": [(b"content-type", b"text/plain")],
                    }
                )
                await send({"type": "http.response.body", "body": b"Unauthorized"})
                return
        await self.app(scope, receive, send)


def _secret(name: str) -> str:
    value = Path(os.environ[name]).read_text().strip()
    if not value:
        raise RuntimeError(f"{name} is empty")
    return value


def _client() -> DAVClient:
    return DAVClient(
        url=os.environ["CALDAV_URL"],
        username=_secret("CALDAV_USERNAME_FILE"),
        password=_secret("CALDAV_PASSWORD_FILE"),
    )


def _calendars(client: DAVClient) -> list[Any]:
    return client.principal().get_calendars()


def _calendar_name(calendar: Any) -> str:
    return (
        calendar.get_display_name() or str(calendar.url).rstrip("/").rsplit("/", 1)[-1]
    )


def _calendar_from(calendars: list[Any], name: str) -> Any:
    matches = [
        calendar
        for calendar in calendars
        if _calendar_name(calendar).casefold() == name.casefold()
    ]
    if not matches:
        raise ValueError(f"calendar not found: {name}")
    if len(matches) > 1:
        raise ValueError(f"calendar name is ambiguous: {name}")
    return matches[0]


def _calendar(client: DAVClient, name: str) -> Any:
    return _calendar_from(_calendars(client), name)


def _temporal(value: str, timezone: str) -> date | datetime:
    if "T" not in value and " " not in value:
        return date.fromisoformat(value)
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=ZoneInfo(timezone))
    return parsed


def _value(value: Any) -> Any:
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    if isinstance(value, bytes):
        return value.decode(errors="replace")
    if isinstance(value, list):
        return [_value(item) for item in value]
    return str(value) if value is not None else None


def _property(component: Any, name: str) -> Any:
    if name not in component:
        return None
    try:
        return _value(component.decoded(name))
    except (AttributeError, ValueError):
        return _value(component[name])


def _event_temporal(component: Any, name: str, timezone: str) -> date | datetime | None:
    if name not in component:
        return None
    value = component.decoded(name)
    if isinstance(value, datetime):
        zone = ZoneInfo(timezone)
        if value.tzinfo is None:
            return value.replace(tzinfo=zone)
        return value.astimezone(zone)
    if isinstance(value, date):
        return value
    raise ValueError(f"{name} is not a date or timestamp")


def _event(
    event: Any, calendar_name: str, timezone: str = "Europe/Berlin"
) -> dict[str, Any]:
    component = event.icalendar_component
    start = _event_temporal(component, "DTSTART", timezone)
    end = _event_temporal(component, "DTEND", timezone)
    return {
        "calendar": calendar_name,
        "uid": _property(component, "UID"),
        "summary": _property(component, "SUMMARY"),
        "start": _value(start),
        "end": _value(end),
        "timezone": timezone,
        "weekday": start.strftime("%A") if start is not None else None,
        "location": _property(component, "LOCATION"),
        "description": _property(component, "DESCRIPTION"),
        "status": _property(component, "STATUS"),
        "etag": event.etag,
    }


def _set(component: Any, name: str, value: Any) -> None:
    component.pop(name, None)
    if value is not None:
        component.add(name, value)


async def _run(function: Any, *args: Any) -> Any:
    return await anyio.to_thread.run_sync(function, *args)


mcp = FastMCP(
    "calendar",
    instructions="Read and manage the user's CalDAV calendars.",
    host=os.environ.get("CALENDAR_MCP_HOST", "127.0.0.1"),
    port=int(os.environ.get("CALENDAR_MCP_PORT", "8765")),
    stateless_http=True,
    json_response=True,
)


@mcp.tool()
async def list_calendars() -> list[dict[str, str]]:
    """List available calendars."""

    def operation() -> list[dict[str, str]]:
        with _client() as client:
            return [
                {"name": _calendar_name(calendar), "url": str(calendar.url)}
                for calendar in _calendars(client)
            ]

    return await _run(operation)


@mcp.tool()
async def list_events(
    start: str,
    end: str,
    calendars: list[str] | None = None,
    timezone: str = "Europe/Berlin",
) -> list[dict[str, Any]]:
    """List sorted events from all calendars, or only the selected calendars."""

    def operation() -> list[dict[str, Any]]:
        with _client() as client:
            available = _calendars(client)
            selected = (
                available
                if calendars is None
                else [_calendar_from(available, name) for name in calendars]
            )
            events = [
                _event(event, _calendar_name(calendar), timezone)
                for calendar in selected
                for event in calendar.search(
                    event=True,
                    start=_temporal(start, timezone),
                    end=_temporal(end, timezone),
                    expand=True,
                )
            ]
            return sorted(
                events,
                key=lambda item: (
                    item["start"] or "",
                    item["calendar"],
                    item["uid"] or "",
                ),
            )

    return await _run(operation)


@mcp.tool()
async def search_events(
    query: str,
    start: str,
    end: str,
    calendars: list[str] | None = None,
    timezone: str = "Europe/Berlin",
) -> list[dict[str, Any]]:
    """Search events from all calendars, or only the selected calendars."""
    events = await list_events(start, end, calendars, timezone)
    needle = query.casefold()
    return [
        event
        for event in events
        if any(
            needle in str(event[field] or "").casefold()
            for field in ("summary", "location", "description")
        )
    ]


@mcp.tool()
async def get_event(calendar: str, uid: str) -> dict[str, Any]:
    """Get one event by its iCalendar UID."""

    def operation() -> dict[str, Any]:
        with _client() as client:
            event = _calendar(client, calendar).get_event_by_uid(uid)
            return _event(event, calendar)

    return await _run(operation)


@mcp.tool()
async def create_event(
    calendar: str,
    summary: str,
    start: str,
    end: str,
    timezone: str = "Europe/Berlin",
    description: str | None = None,
    location: str | None = None,
) -> dict[str, Any]:
    """Create an event. Dates and timestamps use ISO 8601."""

    def operation() -> dict[str, Any]:
        with _client() as client:
            selected = _calendar(client, calendar)
            values: dict[str, Any] = {
                "uid": str(uuid4()),
                "summary": summary,
                "dtstart": _temporal(start, timezone),
                "dtend": _temporal(end, timezone),
            }
            if description is not None:
                values["description"] = description
            if location is not None:
                values["location"] = location
            return _event(selected.add_event(**values), calendar)

    return await _run(operation)


@mcp.tool()
async def update_event(
    calendar: str,
    uid: str,
    summary: str | None = None,
    start: str | None = None,
    end: str | None = None,
    timezone: str = "Europe/Berlin",
    description: str | None = None,
    location: str | None = None,
) -> dict[str, Any]:
    """Update an event. Omitted fields stay unchanged."""
    if (start is None) != (end is None):
        raise ValueError("start and end must be supplied together")
    if all(value is None for value in (summary, start, description, location)):
        raise ValueError("at least one changed field is required")

    def operation() -> dict[str, Any]:
        with _client() as client:
            event = _calendar(client, calendar).get_event_by_uid(uid)
            with event.edit_icalendar_component() as component:
                if summary is not None:
                    _set(component, "SUMMARY", summary)
                if start is not None and end is not None:
                    _set(component, "DTSTART", _temporal(start, timezone))
                    _set(component, "DTEND", _temporal(end, timezone))
                    component.pop("DURATION", None)
                if description is not None:
                    _set(component, "DESCRIPTION", description)
                if location is not None:
                    _set(component, "LOCATION", location)
            event.save()
            return _event(event, calendar)

    return await _run(operation)


@mcp.tool()
async def delete_event(calendar: str, uid: str) -> dict[str, str]:
    """Delete an event."""

    def operation() -> None:
        with _client() as client:
            _calendar(client, calendar).get_event_by_uid(uid).delete()

    await _run(operation)
    return {"deleted": uid, "calendar": calendar}


def main() -> None:
    token = _secret("CALENDAR_MCP_TOKEN_FILE")
    app = BearerAuth(mcp.streamable_http_app(), token)
    uvicorn.run(app, host=mcp.settings.host, port=mcp.settings.port, log_level="info")


if __name__ == "__main__":
    main()

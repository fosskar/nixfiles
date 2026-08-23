import asyncio
import contextlib
import importlib.util
import os
from pathlib import Path
from types import SimpleNamespace

from mcp import types
from mcp.server.lowlevel import server as lowlevel_server

spec = importlib.util.spec_from_file_location(
    "mcp_gateway", Path(os.environ["MCP_GATEWAY_SOURCE"])
)
mcp_gateway = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mcp_gateway)


class Downstream:
    def __init__(self):
        self.calls = []

    async def list_tools(self):
        return SimpleNamespace(
            tools=[
                types.Tool(
                    name="create_event",
                    description="create event",
                    inputSchema={"type": "object"},
                ),
                types.Tool(
                    name="list_events",
                    description="list events",
                    inputSchema={"type": "object"},
                ),
            ]
        )

    async def call_tool(self, name, arguments):
        self.calls.append((name, arguments))
        return types.CallToolResult(
            content=[types.TextContent(type="text", text=f"called {name}")]
        )


class Client:
    def __init__(self, action):
        self.action = action
        self.prompts = []

    async def elicit_form(self, message, schema, related_request_id):
        self.prompts.append((message, schema, related_request_id))
        return SimpleNamespace(action=self.action)


async def call(handler, client, name, arguments):
    request = types.CallToolRequest(
        method="tools/call",
        params=types.CallToolRequestParams(name=name, arguments=arguments),
    )
    context = lowlevel_server.RequestContext(
        request_id="test-request",
        meta=None,
        session=client,
        lifespan_context=None,
        request=request,
    )
    token = lowlevel_server.request_ctx.set(context)
    try:
        return await handler(request)
    finally:
        lowlevel_server.request_ctx.reset(token)


async def main():
    downstream = Downstream()

    @contextlib.asynccontextmanager
    async def session(_server_name, _server):
        yield downstream

    mcp_gateway._session = session
    gateway = mcp_gateway.create_server(
        {
            "calendar": {
                "url": "http://127.0.0.1:8765/mcp",
                "token_credential": "downstream-calendar",
                "approval_tools": ["create_event"],
            }
        }
    )
    handler = gateway.request_handlers[types.CallToolRequest]

    rejected_client = Client("decline")
    rejected = await call(
        handler,
        rejected_client,
        "calendar__create_event",
        {"calendar": "Personal", "summary": "rejected"},
    )
    assert rejected.root.isError is True
    assert "denied" in rejected.root.content[0].text
    assert downstream.calls == []
    assert len(rejected_client.prompts) == 1
    assert "calendar.create_event" in rejected_client.prompts[0][0]
    assert '"summary": "rejected"' in rejected_client.prompts[0][0]

    accepted_client = Client("accept")
    accepted = await call(
        handler,
        accepted_client,
        "calendar__create_event",
        {"calendar": "Personal", "summary": "accepted"},
    )
    assert accepted.root.isError is False
    assert downstream.calls == [
        ("create_event", {"calendar": "Personal", "summary": "accepted"})
    ]
    assert len(accepted_client.prompts) == 1

    read_client = Client("decline")
    read = await call(handler, read_client, "calendar__list_events", {})
    assert read.root.isError is False
    assert downstream.calls[-1] == ("list_events", {})
    assert read_client.prompts == []


asyncio.run(main())
print("mcp gateway approval contract passed")

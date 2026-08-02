from __future__ import annotations

import contextlib
import json
import os
from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any

import uvicorn
from mcp import ClientSession, types
from mcp.client.streamable_http import streamable_http_client
from mcp.server.lowlevel import Server
from mcp.server.streamable_http_manager import StreamableHTTPSessionManager
from mcp.shared._httpx_utils import create_mcp_http_client
from starlette.applications import Starlette
from starlette.routing import Mount


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


def _secret(path: Path) -> str:
    value = path.read_text().strip()
    if not value:
        raise RuntimeError(f"credential is empty: {path.name}")
    return value


def _config() -> dict[str, dict[str, Any]]:
    value = json.loads(Path(os.environ["MCP_GATEWAY_CONFIG"]).read_text())
    servers = value.get("servers")
    if not isinstance(servers, dict) or not servers:
        raise RuntimeError("MCP gateway has no downstream servers")
    return servers


def _split_tool(name: str, servers: dict[str, dict[str, Any]]) -> tuple[str, str]:
    server_name, separator, tool_name = name.partition("__")
    if not separator or server_name not in servers or not tool_name:
        raise ValueError(f"unknown MCP gateway tool: {name}")
    return server_name, tool_name


@contextlib.asynccontextmanager
async def _session(
    server_name: str, server: dict[str, Any]
) -> AsyncIterator[ClientSession]:
    credentials_dir = Path(os.environ["CREDENTIALS_DIRECTORY"])
    token = _secret(credentials_dir / server["token_credential"])
    async with (
        create_mcp_http_client(
            headers={"Authorization": f"Bearer {token}"}
        ) as http_client,
        streamable_http_client(server["url"], http_client=http_client) as (
            read,
            write,
            _,
        ),
        ClientSession(read, write) as session,
    ):
        await session.initialize()
        yield session


def create_server(servers: dict[str, dict[str, Any]]) -> Server:
    gateway = Server("nixfiles-mcp-gateway")

    @gateway.list_tools()
    async def list_tools() -> list[types.Tool]:
        tools: list[types.Tool] = []
        for server_name, server in servers.items():
            async with _session(server_name, server) as session:
                result = await session.list_tools()
            tools.extend(
                tool.model_copy(
                    update={
                        "name": f"{server_name}__{tool.name}",
                        "description": f"[{server_name}] {tool.description or tool.name}",
                    }
                )
                for tool in result.tools
            )
        return tools

    @gateway.call_tool()
    async def call_tool(name: str, arguments: dict[str, Any]) -> types.CallToolResult:
        server_name, tool_name = _split_tool(name, servers)
        server = servers[server_name]
        if tool_name in server.get("approval_tools", []):
            request = gateway.request_context
            result = await request.session.elicit_form(
                f"Allow {server_name}.{tool_name} with these arguments? {json.dumps(arguments, sort_keys=True)}",
                {"type": "object", "properties": {}},
                related_request_id=request.request_id,
            )
            if result.action != "accept":
                raise PermissionError("MCP tool call denied")
        async with _session(server_name, server) as session:
            return await session.call_tool(tool_name, arguments)

    return gateway


def main() -> None:
    servers = _config()
    gateway = create_server(servers)
    session_manager = StreamableHTTPSessionManager(app=gateway)

    async def handle_streamable_http(scope: Any, receive: Any, send: Any) -> None:
        await session_manager.handle_request(scope, receive, send)

    @contextlib.asynccontextmanager
    async def lifespan(_: Starlette) -> AsyncIterator[None]:
        async with session_manager.run():
            yield

    app = Starlette(
        routes=[Mount("/mcp", app=handle_streamable_http)], lifespan=lifespan
    )
    app = BearerAuth(app, _secret(Path(os.environ["MCP_GATEWAY_TOKEN_FILE"])))
    uvicorn.run(
        app,
        host=os.environ.get("MCP_GATEWAY_HOST", "127.0.0.1"),
        port=int(os.environ.get("MCP_GATEWAY_PORT", "8764")),
        log_level="info",
    )


if __name__ == "__main__":
    main()

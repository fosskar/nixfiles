from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from typing import Any

import anyio
from mcp.server.fastmcp import FastMCP
from mcp.server.fastmcp.exceptions import ToolError


def _decide(question: dict[str, Any], text: str) -> dict[str, Any]:
    url = f"{os.environ['LAYA_URL']}/v1/systemone"
    body = {"model": "laya", "state": {"text": text}, "questions": {"q": question}}
    request = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={"content-type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return json.load(response)["answers"]["q"]
    except urllib.error.HTTPError as error:
        raw = error.read().decode(errors="replace")
        try:
            message = json.loads(raw)["error"]["message"]
        except (json.JSONDecodeError, KeyError, TypeError):
            message = raw
        if "too large" in message:
            raise ToolError(
                f"input too large for laya, shorten the text, question or options: {message}"
            ) from error
        raise ToolError(f"laya request failed ({error.code}): {message}") from error
    except OSError as error:
        raise ToolError(f"llama-cpp router unreachable at {url}: {error}") from error


async def _run(question: dict[str, Any], text: str) -> dict[str, Any]:
    return await anyio.to_thread.run_sync(_decide, question, text)


mcp = FastMCP(
    "laya",
    instructions="Answer typed questions about a text with the laya decision model.",
)


@mcp.tool()
async def choice(question: str, text: str, options: list[str]) -> dict[str, Any]:
    """Pick one of the options for the question about the text.

    Returns the chosen option, the probability of each option and a confidence
    from 0 (all options equally likely) to 1.
    """
    if len(options) < 2:
        raise ToolError("at least two options are required")
    if len(set(options)) != len(options):
        raise ToolError("each option must be different")
    return await _run(
        {
            "type": "choice",
            "instructions": question,
            "criteria": {option: "" for option in options},
        },
        text,
    )


@mcp.tool()
async def score(question: str, text: str, levels: list[str]) -> dict[str, Any]:
    """Rate the text on 2 to 10 levels, lowest level first.

    Returns the expected level index weighted by probability (it can lie between
    two levels), the legend of level indexes, the probability of each level and
    a confidence from 0 to 1.
    """
    return await _run(
        {"type": "score", "instructions": question, "criteria": levels},
        text,
    )


@mcp.tool()
async def noul(question: str, text: str) -> dict[str, Any]:
    """Answer a yes/no question about the text.

    Returns noul, the probability that the answer is yes.
    """
    return await _run({"type": "noul", "instructions": question}, text)


def main() -> None:
    mcp.run("stdio")


if __name__ == "__main__":
    main()

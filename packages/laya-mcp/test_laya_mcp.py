import asyncio
import importlib.util
import json
import os
import socket
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "laya_mcp", Path(os.environ["LAYA_MCP_SOURCE"])
)
laya_mcp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(laya_mcp)

requests = []
responses = []


class Router(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers["content-length"])
        requests.append((self.path, json.loads(self.rfile.read(length))))
        status, body = responses.pop(0)
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *_arguments):
        return None


server = HTTPServer(("127.0.0.1", 0), Router)
threading.Thread(target=server.serve_forever, daemon=True).start()
os.environ["LAYA_URL"] = f"http://127.0.0.1:{server.server_port}"


def call(tool, **arguments):
    return asyncio.run(laya_mcp.mcp.call_tool(tool, arguments))[1]


def call_error(tool, **arguments):
    try:
        asyncio.run(laya_mcp.mcp.call_tool(tool, arguments))
    except laya_mcp.ToolError as error:
        return str(error)
    raise AssertionError(f"{tool} did not fail")


tools = asyncio.run(laya_mcp.mcp.list_tools())
assert sorted(tool.name for tool in tools) == ["choice", "noul", "score"]

choice_answer = {
    "type": "choice",
    "choice": "Comedy",
    "probabilities": {"Horror": 0.1, "Comedy": 0.9},
    "confidence": 0.8,
}
responses.append((200, {"model": "laya", "answers": {"q": choice_answer}}))
assert (
    call("choice", question="Genre?", text="a plot", options=["Horror", "Comedy"])
    == choice_answer
)
assert requests.pop() == (
    "/v1/systemone",
    {
        "model": "laya",
        "state": {"text": "a plot"},
        "questions": {
            "q": {
                "type": "choice",
                "instructions": "Genre?",
                "criteria": {"Horror": "", "Comedy": ""},
            }
        },
    },
)

score_answer = {
    "type": "score",
    "score": 1.2,
    "legend": {"0": "Low", "1": "High"},
    "probabilities": {"0": 0.8, "1": 0.2},
    "confidence": 0.6,
}
responses.append((200, {"model": "laya", "answers": {"q": score_answer}}))
assert (
    call("score", question="Spicy?", text="ghost peppers", levels=["Low", "High"])
    == score_answer
)
assert requests.pop()[1]["questions"] == {
    "q": {"type": "score", "instructions": "Spicy?", "criteria": ["Low", "High"]}
}

noul_answer = {"type": "noul", "noul": 0.97}
responses.append((200, {"model": "laya", "answers": {"q": noul_answer}}))
assert call("noul", question="Meat?", text="minced beef") == noul_answer
assert requests.pop()[1]["questions"] == {
    "q": {"type": "noul", "instructions": "Meat?"}
}

responses.append(
    (
        500,
        {
            "error": {
                "code": 500,
                "message": "input (9000 tokens) is too large to process. increase the physical batch size (current batch size: 8192)",
                "type": "server_error",
            }
        },
    )
)
assert "input too large for laya" in call_error("noul", question="Meat?", text="long")
requests.clear()

responses.append(
    (
        400,
        {
            "error": {
                "code": 400,
                "message": 'questions.q: "criteria" must be an array of 2 to 10 levels',
                "type": "invalid_request_error",
            }
        },
    )
)
assert "laya request failed (400): questions.q" in call_error(
    "score", question="Spicy?", text="x", levels=["Low"]
)
requests.clear()

assert "each option must be different" in call_error(
    "choice", question="Genre?", text="x", options=["A", "A"]
)
assert not requests

with socket.socket() as closed:
    closed.bind(("127.0.0.1", 0))
    os.environ["LAYA_URL"] = f"http://127.0.0.1:{closed.getsockname()[1]}"
    assert "llama-cpp router unreachable" in call_error(
        "noul", question="Meat?", text="x"
    )

server.shutdown()
print("laya systemone contract passed")

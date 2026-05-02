/**
 * sketch — quick sketch pad that opens in browser
 * /sketch → opens browser canvas → draw → send
 * image is injected into the next user message automatically
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createServer, type Server } from "node:http";
import { exec } from "node:child_process";
import { readFileSync } from "node:fs";
import { join } from "node:path";
const SKETCH_HTML = readFileSync(join(__dirname, "sketch.html"), "utf-8");

function openBrowser(url: string): void {
  const platform = process.platform;
  let cmd: string;
  if (platform === "darwin") cmd = `open "${url}"`;
  else if (platform === "win32") cmd = `start "" "${url}"`;
  else
    cmd = `xdg-open "${url}" 2>/dev/null || sensible-browser "${url}" 2>/dev/null`;
  exec(cmd);
}

function launchSketchServer() {
  let resolved = false;
  let resolveResult: (value: string | null) => void;
  let resolveReady: () => void;

  const resultPromise = new Promise<string | null>((r) => (resolveResult = r));
  const readyPromise = new Promise<void>((r) => (resolveReady = r));

  let url = "";

  const server: Server = createServer((req, res) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.writeHead(204);
      res.end();
      return;
    }

    if (req.method === "GET" && (req.url === "/" || req.url === "/sketch")) {
      res.writeHead(200, { "Content-Type": "text/html" });
      res.end(SKETCH_HTML);
      return;
    }

    if (req.method === "POST" && req.url === "/submit") {
      let body = "";
      req.on("data", (chunk: string) => (body += chunk));
      req.on("end", () => {
        res.writeHead(200);
        res.end("OK");
        if (!resolved) {
          resolved = true;
          server.close();
          resolveResult(body);
        }
      });
      return;
    }

    if (req.method === "POST" && req.url === "/cancel") {
      res.writeHead(200);
      res.end("OK");
      if (!resolved) {
        resolved = true;
        server.close();
        resolveResult(null);
      }
      return;
    }

    res.writeHead(404);
    res.end();
  });

  server.on("error", (err: Error) => {
    if (!resolved) {
      resolved = true;
      resolveResult(null);
    }
  });

  server.listen(0, "127.0.0.1", () => {
    const addr = server.address();
    if (addr && typeof addr === "object")
      url = `http://127.0.0.1:${addr.port}/sketch`;
    resolveReady();
  });

  const timeout = setTimeout(
    () => {
      if (!resolved) {
        resolved = true;
        server.close();
        resolveResult(null);
      }
    },
    10 * 60 * 1000,
  );

  return {
    get url() {
      return url;
    },
    ready: readyPromise,
    waitForResult: () => resultPromise,
    close: () => {
      clearTimeout(timeout);
      if (!resolved) {
        resolved = true;
        server.close();
        resolveResult(null);
      }
    },
  };
}

export default function (pi: ExtensionAPI) {
  // pending sketch base64 to attach to the next user message
  let pendingSketch: string | null = null;

  // clear pending sketch on session shutdown/switch/reload
  pi.on("session_shutdown", async () => {
    pendingSketch = null;
  });

  // intercept next user input to attach the sketch image
  pi.on("input", async (event, _ctx) => {
    if (!pendingSketch) return { action: "continue" as const };

    const imageData = pendingSketch;
    pendingSketch = null;

    // send as user message with image + user's text, then mark as handled
    pi.sendUserMessage([
      { type: "image", data: imageData, mimeType: "image/png" },
      { type: "text", text: event.text || "Here's my sketch:" },
    ]);

    return { action: "handled" as const };
  });

  pi.registerCommand("sketch", {
    description: "open a sketch pad in browser to draw something for models",

    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("sketch requires interactive mode", "error");
        return;
      }

      const server = launchSketchServer();
      await server.ready;
      openBrowser(server.url);

      const imageBase64 = await ctx.ui.custom<string | null>(
        (_tui, theme, _kb, done) => {
          server.waitForResult().then(done);
          return {
            render(_width: number): string[] {
              return [
                theme.fg("success", "sketch opened in browser"),
                theme.fg("muted", server.url),
                "",
                theme.fg("dim", "press Escape to cancel"),
              ];
            },
            invalidate() {},
            handleInput(data: string) {
              if (data === "\x1b" || data === "\x1b\x1b") {
                server.close();
                done(null);
              }
            },
          };
        },
      );

      if (imageBase64) {
        pendingSketch = imageBase64;
        ctx.ui.notify(
          "sketch ready — type your prompt and it'll be attached",
          "info",
        );
        ctx.ui.setEditorText("describe what's in this sketch:");
      } else {
        ctx.ui.notify("sketch cancelled", "info");
      }
    },
  });
}

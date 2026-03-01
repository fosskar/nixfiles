/**
 * sketch extension - quick sketch pad that opens in browser
 * /sketch → opens browser canvas → draw → Enter sends to models
 *
 * based on pi-sketch by ogulcancelik, with:
 * - shape tools (line, rect, arrow) with live preview
 * - redo support (ctrl+shift+z)
 * - no server ready race condition
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createServer, type Server } from "node:http";
import { exec } from "node:child_process";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
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
            handleInput(data: string) {
              if (data === "\x1b" || data === "\x1b\x1b") {
                server.close();
                done(null);
              }
            },
          };
        },
      );

      try {
        if (imageBase64) {
          const sketchDir = join(tmpdir(), "pi-sketches");
          mkdirSync(sketchDir, { recursive: true });
          const sketchPath = join(sketchDir, `sketch-${Date.now()}.png`);
          writeFileSync(sketchPath, Buffer.from(imageBase64, "base64"));

          const currentText = ctx.ui.getEditorText?.() || "";
          const prefix = currentText ? currentText + "\n" : "";
          ctx.ui.setEditorText(`${prefix}Sketch: ${sketchPath}`);
        } else {
          ctx.ui.notify("sketch cancelled", "info");
        }
      } catch (error) {
        server.close();
        ctx.ui.notify(
          `sketch error: ${error instanceof Error ? error.message : String(error)}`,
          "error",
        );
      }
    },
  });
}

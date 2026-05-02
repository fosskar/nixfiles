/**
 * Diff Extension
 *
 * /diff - pick a changed file and open it in zed's diff view
 * /diff <file> - open specific file's diff directly
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import {
  Container,
  Key,
  matchesKey,
  type SelectItem,
  SelectList,
  Text,
} from "@mariozechner/pi-tui";

interface FileInfo {
  status: string;
  file: string;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("diff", {
    description: "Show git changes and open in Zed's diff view",
    handler: async (args, ctx) => {
      const topResult = await pi.exec("git", ["rev-parse", "--show-toplevel"], {
        cwd: ctx.cwd,
      });
      if (topResult.code !== 0) {
        ctx.ui.notify(`not a git repo: ${topResult.stderr}`, "error");
        return;
      }
      const gitRoot = topResult.stdout.trim();

      const result = await pi.exec("git", ["status", "--porcelain"], {
        cwd: ctx.cwd,
      });
      if (result.code !== 0) {
        ctx.ui.notify(`git status failed: ${result.stderr}`, "error");
        return;
      }
      if (!result.stdout?.trim()) {
        ctx.ui.notify("no changes in working tree", "info");
        return;
      }

      const files: FileInfo[] = [];
      for (const line of result.stdout.split("\n")) {
        if (line.length < 4) continue;
        const status = line.slice(0, 2);
        const file = line.slice(2).trimStart();
        let s: string;
        if (status.includes("M")) s = "M";
        else if (status.includes("A")) s = "A";
        else if (status.includes("D")) s = "D";
        else if (status.includes("?")) s = "?";
        else if (status.includes("R")) s = "R";
        else if (status.includes("C")) s = "C";
        else s = status.trim() || "~";
        files.push({ status: s, file });
      }

      if (files.length === 0) {
        ctx.ui.notify("no changes found", "info");
        return;
      }

      const openDiff = async (f: FileInfo): Promise<void> => {
        const filePath = `${gitRoot}/${f.file}`;

        if (f.status === "?") {
          // untracked — just open
          await pi.exec("zeditor", ["-a", filePath], { cwd: ctx.cwd });
          return;
        }

        // get HEAD version into temp file
        const mktemp = await pi.exec(
          "mktemp",
          ["-t", `diff-${f.file.replace(/\//g, "_")}-XXXXXX`],
          { cwd: ctx.cwd },
        );
        if (mktemp.code !== 0) {
          ctx.ui.notify("failed to create temp file", "error");
          return;
        }
        const tmpFile = mktemp.stdout.trim();

        try {
          const escaped = f.file.replace(/'/g, "'\\''");
          await pi.exec(
            "sh",
            [
              "-c",
              `git show 'HEAD:${escaped}' > '${tmpFile}' 2>/dev/null || true`,
            ],
            { cwd: gitRoot },
          );

          const diffResult = await pi.exec(
            "zeditor",
            ["-a", "--diff", tmpFile, filePath],
            { cwd: ctx.cwd },
          );
          if (diffResult.code !== 0) {
            ctx.ui.notify(`zed diff failed: ${diffResult.stderr}`, "error");
          }
        } finally {
          await pi.exec("rm", ["-f", tmpFile], { cwd: ctx.cwd });
        }
      };

      // direct file arg
      if (args?.trim()) {
        const match = files.find((f) => f.file === args.trim());
        if (match) {
          await openDiff(match);
          return;
        }
        ctx.ui.notify(`file not in changes: ${args.trim()}`, "error");
        return;
      }

      if (!ctx.hasUI) {
        // no UI — diff first file
        await openDiff(files[0]);
        return;
      }

      // file picker
      await ctx.ui.custom<void>((tui, theme, _kb, done) => {
        const container = new Container();
        container.addChild(
          new DynamicBorder((s: string) => theme.fg("accent", s)),
        );
        container.addChild(
          new Text(
            theme.fg("accent", theme.bold(" Select file to diff")),
            0,
            0,
          ),
        );

        const items: SelectItem[] = files.map((f, index) => {
          let sc: string;
          switch (f.status) {
            case "M":
              sc = theme.fg("warning", f.status);
              break;
            case "A":
              sc = theme.fg("success", f.status);
              break;
            case "D":
              sc = theme.fg("error", f.status);
              break;
            case "?":
              sc = theme.fg("muted", f.status);
              break;
            default:
              sc = theme.fg("dim", f.status);
          }
          return { value: String(index), label: `${sc} ${f.file}` };
        });

        const visibleRows = Math.min(items.length, 15);
        let currentIndex = 0;

        const selectList = new SelectList(items, visibleRows, {
          selectedPrefix: (t) => theme.fg("accent", t),
          selectedText: (t) => t,
          description: (t) => theme.fg("muted", t),
          scrollInfo: (t) => theme.fg("dim", t),
          noMatch: (t) => theme.fg("warning", t),
        });
        selectList.onSelect = (item) => {
          const file = files[Number(item.value)];
          if (!file) {
            done();
            return;
          }
          void openDiff(file).finally(() => done());
        };
        selectList.onCancel = () => done();
        selectList.onSelectionChange = (item) => {
          currentIndex = items.indexOf(item);
        };
        container.addChild(selectList);

        container.addChild(
          new Text(
            theme.fg("dim", " ↑↓ navigate • ←→ page • enter open • esc close"),
            0,
            0,
          ),
        );
        container.addChild(
          new DynamicBorder((s: string) => theme.fg("accent", s)),
        );

        return {
          render: (w) => container.render(w),
          invalidate: () => container.invalidate(),
          handleInput: (data) => {
            if (matchesKey(data, Key.left)) {
              currentIndex = Math.max(0, currentIndex - visibleRows);
              selectList.setSelectedIndex(currentIndex);
            } else if (matchesKey(data, Key.right)) {
              currentIndex = Math.min(
                items.length - 1,
                currentIndex + visibleRows,
              );
              selectList.setSelectedIndex(currentIndex);
            } else {
              selectList.handleInput(data);
            }
            tui.requestRender();
          },
        };
      });
    },
  });
}

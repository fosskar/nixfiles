/**
 * Custom Footer Extension
 * Layout: shield model·thinking │ directory │ branch │ context% │ direnv
 * Segments drop from the right when terminal is too narrow.
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

function shortModel(id: string): string {
  let s = id;
  // only strip claude- prefix (gpt-/codex- are ambiguous without prefix)
  s = s.replace(/^claude-/, "");
  // strip date suffixes like -20250514
  s = s.replace(/-\d{8}$/, "");
  // "opus-4-6" → "opus4.6", "sonnet-4" → "sonnet4"
  s = s.replace(/-(\d+)-(\d+)$/, "$1.$2");
  s = s.replace(/-(\d+)$/, "$1");
  return s;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsub = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          // --- context usage ---
          const messages = ctx.sessionManager
            .getBranch()
            .filter(
              (e): e is { type: "message"; message: AssistantMessage } =>
                e.type === "message" && e.message.role === "assistant",
            )
            .map((e) => e.message)
            .filter((m) => m.stopReason !== "aborted");

          const last = messages[messages.length - 1];
          const contextTokens = last
            ? last.usage.input +
              last.usage.output +
              last.usage.cacheRead +
              last.usage.cacheWrite
            : 0;
          const contextWindow = ctx.model?.contextWindow || 0;

          const fmt = (n: number) => {
            if (n < 1000) return n.toString();
            if (n < 10000) return `${(n / 1000).toFixed(1)}k`;
            if (n < 1000000) return `${Math.round(n / 1000)}k`;
            return `${(n / 1000000).toFixed(1)}M`;
          };

          // --- extension statuses ---
          const statuses = footerData.getExtensionStatuses();
          const shieldStatus = statuses.get("safety-net");
          const otherStatusParts: string[] = [];
          for (const [key, value] of statuses) {
            if (key !== "safety-net") otherStatusParts.push(value);
          }

          // --- segments ---

          // 1. shield + model·thinking
          const shield = shieldStatus
            ? theme.fg("mdHeading", "\uf132") + " "
            : "";
          const modelId = shortModel(ctx.model?.id || "no-model");
          const thinkingLevel = pi.getThinkingLevel();
          const thinkingColorMap = {
            off: "thinkingOff",
            minimal: "thinkingMinimal",
            low: "thinkingLow",
            medium: "thinkingMedium",
            high: "thinkingHigh",
            xhigh: "thinkingXhigh",
          } as const;
          const thinkingStr =
            thinkingLevel !== "off"
              ? theme.fg("dim", "·") +
                theme.fg(thinkingColorMap[thinkingLevel], thinkingLevel)
              : "";
          const seg1 = shield + theme.fg("toolTitle", modelId) + thinkingStr;

          // 2. directory
          const folder = ctx.cwd.split("/").pop() || ctx.cwd;
          const seg2 = theme.fg("accent", "\uf07c " + folder);

          // 3. jj (preferred) or git branch fallback
          const { execSync } = require("node:child_process");
          const vcsInfo = (() => {
            try {
              const bookmark = execSync(
                "jj log -r @ --no-graph -T 'bookmarks.map(|b| b.name()).join(\",\")' 2>/dev/null",
                {
                  cwd: ctx.cwd,
                  timeout: 500,
                  encoding: "utf-8",
                  stdio: ["pipe", "pipe", "pipe"],
                },
              ).trim();
              if (bookmark) return { icon: "🥋", label: bookmark };
              const changeId = execSync(
                "jj log -r @ --no-graph -T 'change_id.shortest(4)' 2>/dev/null",
                {
                  cwd: ctx.cwd,
                  timeout: 500,
                  encoding: "utf-8",
                  stdio: ["pipe", "pipe", "pipe"],
                },
              ).trim();
              if (changeId) return { icon: "🥋", label: changeId };
            } catch {
              // not a jj repo
            }
            const rawBranch = footerData.getGitBranch();
            if (rawBranch && rawBranch !== "detached" && rawBranch !== "HEAD")
              return { icon: "\ue725", label: rawBranch };
            return null;
          })();
          const seg3 = vcsInfo
            ? theme.fg("customMessageLabel", vcsInfo.icon + " " + vcsInfo.label)
            : null;

          // 4. context usage (dynamic color by fill level)
          const percentValue =
            contextWindow > 0 ? (contextTokens / contextWindow) * 100 : 0;
          const contextColor =
            percentValue >= 90
              ? "error"
              : percentValue >= 75
                ? "warning"
                : "toolTitle";
          const seg4 = theme.fg(
            contextColor,
            `${percentValue.toFixed(1)}%/${fmt(contextWindow)}`,
          );

          // 5. direnv / other
          const seg5 =
            otherStatusParts.length > 0
              ? otherStatusParts.join(theme.fg("dim", " │ "))
              : null;

          // --- layout: two rows if needed, capped gap spacing ---
          const allSegments = [seg1, seg2, seg3, seg4, seg5].filter(
            (s): s is string => s !== null,
          );

          const pad = 1;
          const innerWidth = width - pad * 2;
          const sepW = 3; // " │ "
          const maxGapPad = 3; // max extra padding per side of separator

          const layoutRow = (segs: string[]): string => {
            const ws = segs.map((s) => visibleWidth(s));
            const content = ws.reduce((a, b) => a + b, 0);
            const gaps = segs.length - 1;
            const baseUsed = content + gaps * sepW;
            const free = Math.max(0, innerWidth - baseUsed);

            // cap per-gap padding so it doesn't get absurdly wide
            const rawPerGap = gaps > 0 ? Math.floor(free / gaps) : 0;
            const perGap = Math.min(rawPerGap, maxGapPad * 2);

            const dimPipe = theme.fg("dim", "│");
            let row = " ".repeat(pad);
            for (let i = 0; i < segs.length; i++) {
              row += segs[i];
              if (i < segs.length - 1) {
                const half = Math.floor(perGap / 2);
                const otherHalf = perGap - half;
                row +=
                  " ".repeat(1 + half) + dimPipe + " ".repeat(1 + otherHalf);
              }
            }
            return row;
          };

          // figure out how many fit on row 1
          const fitsIn = (segs: string[]) => {
            const w =
              segs.reduce((a, s) => a + visibleWidth(s), 0) +
              (segs.length - 1) * sepW;
            return w <= innerWidth;
          };

          let row1Segs = allSegments;
          let row2Segs: string[] = [];

          if (!fitsIn(allSegments)) {
            // try splitting: keep removing from end of row1 into row2
            for (let split = allSegments.length - 1; split >= 1; split--) {
              const r1 = allSegments.slice(0, split);
              const r2 = allSegments.slice(split);
              if (fitsIn(r1)) {
                row1Segs = r1;
                row2Segs = r2;
                break;
              }
            }
          }

          const lines = [truncateToWidth(layoutRow(row1Segs), width)];
          if (row2Segs.length > 0) {
            lines.push(truncateToWidth(layoutRow(row2Segs), width));
          }
          return lines;
        },
      };
    });
  });
}

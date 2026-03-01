/**
 * Custom Footer Extension
 * Layout: shield model · thinking │ directory │ branch │ context% │ direnv
 * Evenly distributed across terminal width.
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

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

          // 1. shield + model · thinking
          // orange shield (mdHeading = #f0c674, matches [Extensions] orange)
          const shield = shieldStatus
            ? theme.fg("mdHeading", "\uf132") + "  "
            : "";
          const modelId = ctx.model?.id || "no-model";
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
              ? theme.fg("dim", " · ") +
                theme.fg(thinkingColorMap[thinkingLevel], thinkingLevel)
              : "";
          const seg1 = shield + theme.fg("toolTitle", modelId) + thinkingStr;

          // 2. directory
          const folder = ctx.cwd.split("/").pop() || ctx.cwd;
          const seg2 = theme.fg("accent", "\uf07c " + folder);

          // 3. jj (preferred) or git branch fallback
          const { execSync } = require("node:child_process");
          const vcsInfo = (() => {
            // try jj first
            try {
              const bookmark = execSync(
                "jj log -r @ --no-graph -T 'bookmarks.map(|b| b.name()).join(\",\")'",
                { cwd: ctx.cwd, timeout: 500, encoding: "utf-8" },
              ).trim();
              if (bookmark) return { icon: "🥋", label: bookmark };
              // no bookmark on @, show short change id
              const changeId = execSync(
                "jj log -r @ --no-graph -T 'change_id.shortest(4)'",
                { cwd: ctx.cwd, timeout: 500, encoding: "utf-8" },
              ).trim();
              if (changeId) return { icon: "🥋", label: changeId };
            } catch {
              // not a jj repo
            }
            // git fallback
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

          const segments = [seg1, seg2, seg3, seg4, seg5].filter(
            (s): s is string => s !== null,
          );

          const pad = 3; // left/right padding
          const innerWidth = width - pad * 2;

          const segWidths = segments.map((s) => visibleWidth(s));
          const totalContent = segWidths.reduce((a, b) => a + b, 0);
          const gaps = segments.length - 1;
          const sepWidth = 3; // " │ " = 3 visible chars
          const totalUsed = totalContent + gaps * sepWidth;
          const freeSpace = Math.max(0, innerWidth - totalUsed);

          const spacePerGap = gaps > 0 ? Math.floor(freeSpace / gaps) : 0;
          const leftover =
            gaps > 0 ? freeSpace - spacePerGap * gaps : freeSpace;

          const dimPipe = theme.fg("dim", "│");
          let result = " ".repeat(pad);
          for (let i = 0; i < segments.length; i++) {
            result += segments[i];
            if (i < segments.length - 1) {
              const extra = i < leftover ? 1 : 0;
              const half = Math.floor((spacePerGap + extra) / 2);
              const otherHalf = spacePerGap + extra - half;
              result +=
                " ".repeat(1 + half) + dimPipe + " ".repeat(1 + otherHalf);
            }
          }

          return [truncateToWidth(result, width)];
        },
      };
    });
  });
}

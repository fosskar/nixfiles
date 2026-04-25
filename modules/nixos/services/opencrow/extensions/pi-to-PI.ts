import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// Replaces standalone lowercase "pi" with "PI" in the system prompt.
// Uses lookbehind/lookahead so paths like ~/.pi/ and pi-coding-agent are untouched.

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    if (ctx.model?.provider !== "anthropic") return;
    const replaced = event.systemPrompt.replace(
      /(?<=^|\s)pi(?=\s|[,.]|$)/gm,
      "PI",
    );
    if (replaced === event.systemPrompt) return;
    return { systemPrompt: replaced };
  });
}

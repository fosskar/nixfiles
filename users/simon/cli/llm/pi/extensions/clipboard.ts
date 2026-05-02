// clipboard extension — copies text via OSC52 escape sequence
import { Type } from "typebox";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "copy_to_clipboard",
    label: "Copy to Clipboard",
    description:
      "Copy text to the user's system clipboard. Use this when the user asks you to " +
      "put something in their clipboard, write a draft reply to clipboard, or copy any " +
      "generated text for easy pasting. The text will be available for pasting immediately.",
    parameters: Type.Object({
      text: Type.String({ description: "The text to copy to the clipboard" }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const { text } = params as { text: string };
      const b64 = Buffer.from(text, "utf-8").toString("base64");
      process.stdout.write(`\x1b]52;c;${b64}\x07`);

      if (ctx.hasUI) {
        ctx.ui.notify(`copied ${text.length} chars to clipboard`, "info");
      }

      return {
        content: [
          {
            type: "text",
            text: `copied ${text.length} characters to clipboard.`,
          },
        ],
        details: {},
      };
    },
  });
}

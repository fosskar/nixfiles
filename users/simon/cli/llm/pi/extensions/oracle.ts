/**
 * oracle — get a second opinion from another AI model
 *
 * /oracle <prompt>              - opens model picker, then queries
 * /oracle -m gpt-4o <prompt>    - direct to specific model
 * /oracle -f file.ts <prompt>   - include file(s) in context
 */

import {
  complete,
  type Api,
  type UserMessage,
  type Model,
} from "@mariozechner/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
} from "@mariozechner/pi-coding-agent";
import {
  BorderedLoader,
  convertToLlm,
  serializeConversation,
} from "@mariozechner/pi-coding-agent";
import { Text, matchesKey, visibleWidth } from "@mariozechner/pi-tui";
import { readFile } from "node:fs/promises";
import * as path from "node:path";

interface AvailableModel {
  provider: string;
  modelId: string;
  name: string;
  model: Model<Api>;
  apiKey: string;
  headers?: Record<string, string>;
}

/**
 * oracle result display with add-to-context option
 */
class OracleResultComponent {
  private result: string;
  private modelName: string;
  private prompt: string;
  private selected: number = 0; // 0 = yes, 1 = no
  private scrollOffset: number = 0;
  private onDone: (addToContext: boolean) => void;
  private tui: { requestRender: () => void };
  private theme: any;
  private cachedLines: string[] = [];
  private cachedWidth = 0;

  constructor(
    result: string,
    modelName: string,
    prompt: string,
    tui: { requestRender: () => void },
    theme: any,
    onDone: (addToContext: boolean) => void,
  ) {
    this.result = result;
    this.modelName = modelName;
    this.prompt = prompt;
    this.tui = tui;
    this.theme = theme;
    this.onDone = onDone;
  }

  handleInput(data: string): void {
    if (matchesKey(data, "escape") || data === "n" || data === "N") {
      this.onDone(false);
      return;
    }

    if (matchesKey(data, "return") || matchesKey(data, "enter")) {
      this.onDone(this.selected === 0);
      return;
    }

    if (data === "y" || data === "Y") {
      this.onDone(true);
      return;
    }

    if (
      matchesKey(data, "left") ||
      matchesKey(data, "right") ||
      data === "h" ||
      data === "l" ||
      matchesKey(data, "tab")
    ) {
      this.selected = this.selected === 0 ? 1 : 0;
      this.cachedWidth = 0;
      this.tui.requestRender();
    }

    if (matchesKey(data, "up") || data === "k") {
      this.scrollOffset = Math.max(0, this.scrollOffset - 1);
      this.cachedWidth = 0;
      this.tui.requestRender();
    } else if (matchesKey(data, "down") || data === "j") {
      this.scrollOffset++;
      this.cachedWidth = 0;
      this.tui.requestRender();
    }
  }

  invalidate(): void {
    this.cachedWidth = 0;
  }

  render(width: number): string[] {
    if (this.cachedWidth === width) return this.cachedLines;

    const t = this.theme;
    const lines: string[] = [];
    const boxWidth = Math.min(80, width - 4);
    const contentWidth = boxWidth - 4;
    const maxResultLines = 15;

    const padLine = (line: string): string => {
      const len = visibleWidth(line);
      return line + " ".repeat(Math.max(0, width - len));
    };

    const boxLine = (content: string): string => {
      const len = visibleWidth(content);
      const padding = Math.max(0, boxWidth - 2 - len);
      return (
        t.fg("dim", "│ ") + content + " ".repeat(padding) + t.fg("dim", " │")
      );
    };

    const wrapText = (text: string, maxWidth: number): string[] => {
      const wrapped: string[] = [];
      for (const paragraph of text.split("\n")) {
        if (paragraph.length <= maxWidth) {
          wrapped.push(paragraph);
        } else {
          let remaining = paragraph;
          while (remaining.length > maxWidth) {
            let breakPoint = remaining.lastIndexOf(" ", maxWidth);
            if (breakPoint === -1) breakPoint = maxWidth;
            wrapped.push(remaining.slice(0, breakPoint));
            remaining = remaining.slice(breakPoint + 1);
          }
          if (remaining) wrapped.push(remaining);
        }
      }
      return wrapped;
    };

    lines.push("");
    lines.push(padLine(t.fg("dim", "╭" + "─".repeat(boxWidth) + "╮")));
    lines.push(
      padLine(
        boxLine(
          t.bold(t.fg("accent", `🔮 Oracle Response (${this.modelName})`)),
        ),
      ),
    );
    lines.push(padLine(t.fg("dim", "├" + "─".repeat(boxWidth) + "┤")));

    const promptPreview =
      this.prompt.length > contentWidth - 10
        ? this.prompt.slice(0, contentWidth - 13) + "..."
        : this.prompt;
    lines.push(padLine(boxLine(t.fg("dim", "Q: ") + promptPreview)));
    lines.push(padLine(t.fg("dim", "├" + "─".repeat(boxWidth) + "┤")));

    const resultLines = wrapText(this.result, contentWidth);
    const visibleLines = resultLines.slice(
      this.scrollOffset,
      this.scrollOffset + maxResultLines,
    );

    for (const line of visibleLines) {
      lines.push(padLine(boxLine(line)));
    }

    for (let i = visibleLines.length; i < Math.min(maxResultLines, 5); i++) {
      lines.push(padLine(boxLine("")));
    }

    if (resultLines.length > maxResultLines) {
      const scrollInfo = t.fg(
        "dim",
        ` ↑↓ scroll (${this.scrollOffset + 1}-${Math.min(this.scrollOffset + maxResultLines, resultLines.length)}/${resultLines.length})`,
      );
      lines.push(padLine(boxLine(scrollInfo)));
    }

    lines.push(padLine(t.fg("dim", "├" + "─".repeat(boxWidth) + "┤")));
    lines.push(
      padLine(boxLine(t.bold("Add to current conversation context?"))),
    );
    lines.push(padLine(boxLine("")));

    const yesBtn =
      this.selected === 0
        ? t.fg("success", t.bold(" [ YES ] "))
        : t.fg("dim", "   YES   ");
    const noBtn =
      this.selected === 1
        ? t.fg("warning", t.bold(" [ NO ] "))
        : t.fg("dim", "   NO   ");

    lines.push(padLine(boxLine(`       ${yesBtn}          ${noBtn}`)));
    lines.push(padLine(boxLine("")));

    lines.push(padLine(t.fg("dim", "├" + "─".repeat(boxWidth) + "┤")));
    lines.push(
      padLine(
        boxLine(
          t.fg("dim", "←→/Tab") +
            " switch  " +
            t.fg("dim", "Enter") +
            " confirm  " +
            t.fg("dim", "Y/N") +
            " quick",
        ),
      ),
    );
    lines.push(padLine(t.fg("dim", "╰" + "─".repeat(boxWidth) + "╯")));
    lines.push("");

    this.cachedLines = lines;
    this.cachedWidth = width;
    return lines;
  }
}

async function getAvailableModels(
  ctx: ExtensionContext,
): Promise<AvailableModel[]> {
  const models: AvailableModel[] = [];
  const available = ctx.modelRegistry.getAvailable();

  for (const model of available) {
    // skip current model — we want a different opinion
    if (ctx.model && model.id === ctx.model.id) continue;

    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth.ok) continue;

    models.push({
      provider: model.provider,
      modelId: model.id,
      name: model.name ?? model.id,
      model,
      apiKey: auth.apiKey ?? "",
      headers: auth.headers,
    });
  }

  return models;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("oracle", {
    description: "Get a second opinion from another AI model",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("oracle requires interactive mode", "error");
        return;
      }

      const availableModels = await getAvailableModels(ctx);

      if (availableModels.length === 0) {
        ctx.ui.notify(
          "no alternative models available. check API keys.",
          "error",
        );
        return;
      }

      // parse args
      const trimmedArgs = args?.trim() || "";
      if (!trimmedArgs) {
        ctx.ui.notify(
          "usage: /oracle <prompt> or /oracle -f file.ts <prompt>",
          "error",
        );
        return;
      }

      let modelArg: string | undefined;
      const files: string[] = [];
      const promptParts: string[] = [];

      const tokens = trimmedArgs.split(/\s+/);
      let i = 0;
      while (i < tokens.length) {
        const token = tokens[i];
        if (token === "-m" || token === "--model") {
          i++;
          if (i < tokens.length) modelArg = tokens[i];
        } else if (token === "-f" || token === "--file") {
          i++;
          if (i < tokens.length) files.push(tokens[i]);
        } else {
          promptParts.push(...tokens.slice(i));
          break;
        }
        i++;
      }

      const prompt = promptParts.join(" ");
      if (!prompt) {
        ctx.ui.notify("no prompt provided", "error");
        return;
      }

      // if model specified directly, skip picker
      if (modelArg) {
        const found = availableModels.find(
          (m) =>
            m.modelId === modelArg ||
            m.modelId.includes(modelArg!) ||
            m.name.toLowerCase().includes(modelArg!.toLowerCase()),
        );
        if (!found) {
          ctx.ui.notify(`model "${modelArg}" not available`, "error");
          return;
        }
        await executeOracle(pi, ctx, prompt, files, found);
        return;
      }

      // model picker via ctx.ui.select
      const choices = availableModels.map((m) => `${m.name} (${m.provider})`);
      const picked = await ctx.ui.select("🔮 Oracle — pick a model:", choices);
      if (picked === undefined) {
        ctx.ui.notify("cancelled", "info");
        return;
      }
      const selectedIdx = choices.indexOf(picked);
      if (selectedIdx === -1) return;

      await executeOracle(pi, ctx, prompt, files, availableModels[selectedIdx]);
    },
  });

  // custom renderer for oracle responses
  pi.registerMessageRenderer("oracle-response", (message, options, theme) => {
    const { expanded } = options;
    const details = (message.details || {}) as {
      modelName?: string;
      files?: string[];
    };

    let text = theme.fg(
      "accent",
      `🔮 Oracle (${details.modelName || "unknown"}):\n\n`,
    );
    text += message.content;

    const files = details.files ?? [];
    if (expanded && files.length > 0) {
      text += "\n\n" + theme.fg("dim", `Files: ${files.join(", ")}`);
    }

    return new Text(text, 0, 0);
  });
}

async function executeOracle(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  prompt: string,
  files: string[],
  model: AvailableModel,
): Promise<void> {
  // get conversation context from current session
  const branch = ctx.sessionManager.getBranch();
  const messages = branch
    .filter(
      (entry): entry is SessionEntry & { type: "message" } =>
        entry.type === "message",
    )
    .map((entry) => entry.message);

  let conversationContext = "";
  if (messages.length > 0) {
    const llmMessages = convertToLlm(messages);
    conversationContext = serializeConversation(llmMessages);
  }

  // build context from files (async)
  let fileContext = "";
  for (const file of files) {
    try {
      const fullPath = path.resolve(ctx.cwd, file);
      const content = await readFile(fullPath, "utf-8");
      fileContext += `\n\n--- File: ${file} ---\n${content}`;
    } catch (err) {
      fileContext += `\n\n--- File: ${file} ---\n[Error reading file: ${err}]`;
    }
  }

  // build full prompt with conversation context
  let fullPrompt = "";
  if (conversationContext) {
    fullPrompt += `## Current Conversation Context\n\n${conversationContext}\n\n`;
  }
  fullPrompt += `## Question for Second Opinion\n\n${prompt}`;
  if (fileContext) {
    fullPrompt += `\n\n## Additional Files${fileContext}`;
  }

  // call the model
  const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
    const loader = new BorderedLoader(tui, theme, `🔮 Asking ${model.name}...`);
    loader.onAbort = () => done(null);

    const doQuery = async () => {
      const userMessage: UserMessage = {
        role: "user",
        content: [{ type: "text", text: fullPrompt }],
        timestamp: Date.now(),
      };

      const response = await complete(
        model.model,
        {
          systemPrompt: `You are providing a second opinion on a coding conversation.
You have access to the full conversation context between the user and their primary AI assistant.
Your job is to:
1. Understand what they've been discussing
2. Answer the specific question they're asking you
3. Point out if you disagree with any decisions made
4. Be concise but thorough

Focus on being helpful and providing a fresh perspective.`,
          messages: [userMessage],
        },
        { apiKey: model.apiKey, headers: model.headers, signal: loader.signal },
      );

      if (response.stopReason === "aborted") return null;

      return response.content
        .filter((c): c is { type: "text"; text: string } => c.type === "text")
        .map((c) => c.text)
        .join("\n");
    };

    doQuery()
      .then(done)
      .catch((err) => {
        console.error("Oracle error:", err);
        done(null);
      });

    return loader;
  });

  if (result === null) {
    ctx.ui.notify("cancelled or failed", "warning");
    return;
  }

  // show result and ask if user wants to add to context
  const addToContext = await ctx.ui.custom<boolean>((tui, theme, _kb, done) => {
    const component = new OracleResultComponent(
      result,
      model.name,
      prompt,
      tui,
      theme,
      (add) => done(add),
    );

    return {
      render: (w) => component.render(w),
      invalidate: () => component.invalidate(),
      handleInput: (data) => component.handleInput(data),
    };
  });

  if (addToContext) {
    pi.sendMessage({
      customType: "oracle-response",
      content: result,
      display: true,
      details: {
        model: model.modelId,
        modelName: model.name,
        files,
        prompt,
      },
    });
    ctx.ui.notify("oracle response added to context", "info");
  } else {
    ctx.ui.notify("oracle response discarded", "info");
  }
}

---
name: brave-search
description: Web search via Brave Search API using the `bx` CLI. Use for current information, docs, facts, and pre-extracted web context.
---

# Brave Search

Use `bx` from `brave-search-cli`.

`bx` reads the API key from `BRAVE_SEARCH_API_KEY` or its config file.

## Search for LLM context

Use `context` by default. It returns clean, token-budgeted snippets suitable for answers.

```bash
bx context "query" --max-tokens 4096
bx context "query" --count 5 --threshold strict
bx context "query" --include-site docs.rs --max-tokens 4096
```

Shortcut:

```bash
bx "query"
```

## Raw web results

```bash
bx web "query" | jq .
```

## News / images / answers

```bash
bx news "query" --freshness pd
bx images "query"
bx answers "query"
```

## Rules

- Prefer `bx context` over raw browser/curl fetches.
- Keep output bounded with `--max-tokens`.
- Do not print or expose API keys.

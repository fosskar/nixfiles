---
name: llm-wiki
description: File sources into the private llm-wiki and ingest them into wiki pages. Use when the user shares a URL to keep, says "add this to the wiki", or asks to ingest, query, or lint the wiki.
---

The wiki is `fosskar/llm-wiki` on GitHub. Work on it remotely with `gh`. Do not
clone it and do not look for a local copy.

The repo owns the rules. Read the schema first, every time, and follow it:

```bash
gh api repos/fosskar/llm-wiki/contents/AGENTS.md --jq '.content' | base64 -d
```

It defines the layers, page conventions, frontmatter, the ingest, query and lint
workflows, and the log format. Do not restate or improvise them here. Read
`llm-wiki.md` in the same repo when the schema does not cover a case.

## Remote access

Read a file or list a directory:

```bash
gh api repos/fosskar/llm-wiki/contents/<path> --jq '.content' | base64 -d
gh api repos/fosskar/llm-wiki/contents/<dir> --jq '.[].name'
```

Create a file:

```bash
gh api -X PUT repos/fosskar/llm-wiki/contents/<path> \
  -f message="<subject>" \
  -f content="$(base64 -w0 <local-file>)"
```

Update a file — needs its current blob sha:

```bash
sha=$(gh api repos/fosskar/llm-wiki/contents/<path> --jq '.sha')
gh api -X PUT repos/fosskar/llm-wiki/contents/<path> \
  -f message="<subject>" -f sha="$sha" \
  -f content="$(base64 -w0 <local-file>)"
```

Each write is one commit. A 422 on create means the path exists — for a raw
source pick a more specific slug rather than overwriting, since sources are
immutable once they land.

## Capturing a link

The user shares a link. Fetch it with the `fetch` tool, `readability: true`, and
write it to `raw/sources/<dash-case>.md`. Match the frontmatter of the files
already there.

Then ingest it immediately. Override the schema here: do not stop to discuss
takeaways, run the whole pass and report what changed afterwards.

Given several links at once, capture all of them first, then ingest them one at
a time. Each source gets its own integration pass and its own `log.md` entry.

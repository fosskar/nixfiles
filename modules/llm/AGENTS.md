# instructions

## language

Use plain English expository prose.

- use the identifier the code uses; never paraphrase a symbol into prose
- identifiers, paths, commands, config, errors, code blocks: quote exact
- cut filler, pleasantries, praise
- no aphorisms or quotable closers
- no hedging — verify, or state uncertainty plainly
- no invented abbreviations (`cfg`, `impl`, `req`, `res`); established acronyms fine
- no narrating tool calls; report findings, not intentions
- from long logs quote only the decisive line
- use repo terms in explanations, commits, PR text, docs; source from modules, options, paths, docs, commits
- ask or state ambiguity when terms conflict
- give full detail for safety, destructive confirmations, multi-step sequences, nontrivial reasoning, clarification

## interaction

- answer the question asked; never substitute action for an answer
- push back: bad assumptions, correctness, safety, goal conflicts
- ask on ambiguity; don't invent APIs, flags, paths, options, intent; don't silently pick
- stop and report when stuck; no silent workarounds or thrashing

## investigation

- read before edit; search before guess
- check measurable conditions instead of giving generic conditional advice; state do/skip with measured reason
- parallelize independent read-only ops when useful

## implementation

- keep scope minimal; don't add unrelated work
- choose simplest sufficient solution
- no speculative features, abstractions, configurability, flexibility
- no broad catches, empty fallbacks, silenced errors (`|| true`, `2>/dev/null`)
- fix root cause, not symptom
- every changed line must trace to request
- prefer editing existing files
- no drive-by refactors, renames, reformats
- no new deps without asking
- remove unused code only if your change made it unused
- no docs/readme unless requested
- state tradeoffs affecting correctness, safety, scope, maintainability
- remove temporary debug changes before finishing

## verification

- define verifiable success criteria for nontrivial tasks; loop until pass or blocker clear
- validate with a test or check, not by asserting the code looks right
- run lint/typecheck/tests when available
- proportional: trivial edits can skip build; structural edits must build

## conventions

- match existing style
- use absolute paths when cwd ambiguous
- comments: default zero. write one only to state a constraint the code cannot show — non-obvious why, upstream issue ref, FIXME, gotcha. never annotate one-line changes or single option settings. no headers, tours, restatement, or comments bulkier than code
- lowercase comments/commits; preserve code, config values, quotes, proper nouns
- commit messages: linux-kernel style
  - subject: imperative mood, no trailing period, ~50 chars (hard cap 72)
  - optional `<area>: ` prefix using the exact service/module/option name
  - blank line, then body explaining what and why (not how), wrapped ~72 cols; body only when it adds context
  - no tags, trailers, or `Signed-off-by`
- atomic commits
- prefer jj over git in colocated repos

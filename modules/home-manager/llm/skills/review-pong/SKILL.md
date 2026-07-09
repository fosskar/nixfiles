---
name: review-pong
description: "Adversarial code review: a second model attacks the review's findings until the verdicts go stable."
disable-model-invocation: true
---

# Review Pong

A code review, then an adversarial loop: a **critic** — a _different_ model — attacks the findings; the reviewer defends with evidence. A finding that survives challenges is worth more than one nobody attacked. Everything happens in-conversation; write no files.

## 1. Review

Run the code-review skill against the fixed point the user named. If the conversation already holds a fresh review, reuse it. Number the findings.

## 2. Pick the critic

Use the harness's cross-model mechanism, whichever exists:

- the `second_opinion` tool (from the oracle extension), with `model` set
- an in-session completion helper with a model parameter (use the strongest available model)
- a subagent pinned to a different model

Same model as the reviewer is pointless — the value is a different prior. No cross-model mechanism at all? Say so and stop; a self-critique is not this skill.

## 3. Critic round

Send the critic: the diff (or the relevant hunks), the numbered findings with their evidence, and the standards sources the review used. The brief:

> Attack each finding: is it wrong, overblown, or missing context the diff actually contains? Cite the hunk that defeats it. Then name anything the reviewer missed entirely. Verdict per finding: reject / downgrade / uphold. No politeness, no summary praise.

## 4. Reviewer verdict

For each critic response, re-check against the actual code — the critic argues from the excerpt, you have the repo:

- **confirmed** — challenge re-checked and beaten, evidence cited
- **amended** — challenge partially right; finding reworded or downgraded
- **withdrawn** — critic is right; finding dies
- Critic's _new_ findings enter the table only after you verify them against the repo — a critic hallucinating a hunk is common; unverified claims die at the door.

## 5. Converge

A round is **stable** when no finding changed status and no verified new finding entered. Loop critic → verdict until a stable round, capped at 3 rounds. Not converged at the cap? Report the contested findings as contested — disagreement between models is itself signal.

## 6. Report

Final findings table: number, finding, severity, and adversarial history (`survived 2 challenges`, `amended round 1`, `added by critic, verified`). Withdrawn findings listed one-line at the bottom — what the review almost got wrong is part of the result.

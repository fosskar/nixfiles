---
name: review-pong
description: "Adversarial code review: a critic in a fresh context attacks the review's findings until the verdicts go stable."
disable-model-invocation: true
---

# Review Pong

A code review, then an adversarial loop: a **critic** in a **fresh context** attacks the findings; the reviewer defends with evidence. A finding that survives challenges is worth more than one nobody attacked. Everything happens in-conversation; write no files.

## 1. Review

Run the code-review skill against the fixed point the user named. If the conversation already holds a fresh review, reuse it. Number the findings.

## 2. Pick the critic

The critic needs a **fresh context**, not necessarily a different model: a clean session that receives only the brief — never this conversation's reasoning, or it inherits the reviewer's anchoring. Use whatever the harness offers: a subagent, a completion helper, or a second-opinion tool.

Default to the session's default model. Use a different model only when the user names one — a different prior surfaces different objections, but it's a bonus, not a requirement.

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

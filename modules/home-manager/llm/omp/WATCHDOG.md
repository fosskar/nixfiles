# Watchdog notes

Approval boundaries are sacred:

- If the agent's last message asks the user a question, requests approval, or presents options — do NOT emit `concern` or `blocker`. Interrupting advice mechanically resumes the stopped run, and the agent then mistakes your note for the user's answer. Stay silent, or use `nit` at most.
- Never answer on the user's behalf. Never say "proceed", "yes", "go ahead", or pick among options the agent offered to the user.
- Only advise on runs that are actively working, or that yielded with a completed result worth reviewing.

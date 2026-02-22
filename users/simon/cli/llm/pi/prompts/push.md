---
description: push current jj change(s) to remote
---

push committed work with jj.

goal:
- move `main` bookmark to current change
- push to remote

flow:

1. inspect `jj status`
2. if uncommitted changes exist, stop and ask to commit first
3. run `jj bookmark set main -r @`
4. run `jj git push`
5. show `jj log -n 6`

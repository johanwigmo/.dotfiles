---
name: git-commit
description:  Write and run a git commit with a conventional commit message. Use when asked to commit, or when staged changes are ready to be committed. 
---

## Steps

1. Run `git diff --staged` to review what's staged
2. Craft a conventional commit message: 
    - Format: `type(scope): description`
    - Types: feature, fix, refactor, docs, chore, test, style
    - Under 72 chars, imperative mood
    - Add a body only if the why isn't obvious from the diff
3. Run `git commit -m "Message"`

## Rules

- If nothing is staged, check `git status` and ask before staging anything
- Never stage or commit files the user hasn't mentioned

---
name: add-to-inbox
description: Capture a task, idea, research topic, or follow-up to the notes inbox. Use when the user asks to save something, mentions something worth following up on, or when you notice something mid-session that deserves attention later.
---

Inbox file: ~/Documents/notes/todo/inbox.md

## Steps

1. Read the inbox file to see current state and avoid duplicates
2. Append new item(s) at the bottom
3. Confirm briefly to the user what was added

## Entry format

```
- [ ] {description}
```

Optional inline metadata - add when clearly relevant, don't force it: 
- `+project-name` - project tag
- `@context` - context tag (e.g. `@work`, `@home`)
- Indented (four spaces) sub-bullet for a URL, note, or short context

### Examples

```
- [ ] Research standing desk mats — which work well with a balance board
    - https://example.com/article
- [ ] Look into calendar sync options between iPhone and notes system +meta
    due: 2026-12-01
- [ ] Consider a "reading log" section in the monthly review template +meta
```

## Rules

- Always use `[ ]` - never pre-mark as done, in-progress, or cancelled
- Keep descriptions concise but specific enough to act on later
- Don't add tags unless you're confient they're right
- If adding multiple items, group them under a blank line at the bottom
- Never reorganize or delete existing content


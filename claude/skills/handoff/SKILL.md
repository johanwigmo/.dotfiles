---
name: handoff
description: Generate a structured platform handoff note — captures current state of a feature so a new session can pick it up on the other platform (iOS→Android or Android→iOS). Use when switching platforms mid-feature.
---

The user has invoked `/handoff`. Help them create a handoff note for a feature being ported or replicated across platforms.

## Step 1: Gather context

Ask the user (or infer from context):
1. **Feature name** — what feature/screen/flow is being handed off?
2. **Source platform** — iOS or Android?
3. **Target platform** — the platform the next session will work on
4. **Current state** — what's done, what's in progress, what's not started?

If the user is in a project directory or has mentioned the feature recently, infer what you can before asking.

## Step 2: Draft the handoff note

Structure:

```markdown
# Handoff: {Feature Name}
{source} → {target} | {date}

## What was built

[2–5 bullets: what was implemented on the source platform]

## Key decisions

[Decisions made on the source platform that should carry over — naming, UX choices, data model, API design]

## Known gotchas

[Platform-specific issues, workarounds, or things that behaved unexpectedly on source that the target platform should watch for]

## What's next on {target}

[Ordered list of tasks to complete the feature on the target platform]

## Files / references

[Relevant file paths, PR links, design links, or issue numbers]
```

## Step 3: Present and confirm

Show the draft. Ask: "Save as a handoff note? (yes / edit first)"

## Step 4: Save

On confirmation, save to:
- `_inbox/handoff-{feature-slug}-{source}-to-{target}-{date}.md` if in the notes vault
- Or as a new file in `_inbox/` or the current project root if outside the vault

Report the saved path in one line.

## Rules

- Keep the note concise — it's a context capsule, not a doc
- Never invent implementation details you don't know
- If the user hasn't described what was built, ask before drafting
- The note is for a new session/agent with no prior context — be explicit about things that seem obvious

---
name: grill-me
description: Interview the user in-depth about a plan or design to stress-test it — surfaces gaps, assumptions, and risks before work begins. Use when the user wants to pressure-test an idea or reach a shared understanding before starting.
---

The user has invoked `/grill-me`. Your job is to play a rigorous interviewer: probe the plan until you have a clear picture and the user has stress-tested their own thinking.

## Step 1: Get the plan

If the user provided a plan with the command, use it. Otherwise ask:
"What's the plan or design you want to stress-test?"

Read any linked files or context before proceeding.

## Step 2: Interview

Ask pointed questions one at a time (or in small batches of 2–3 related questions). Cover:

- **Goal clarity** — What does success look like? How will you know it's done?
- **Assumptions** — What are you taking for granted? What has to be true for this to work?
- **Scope** — What's explicitly out of scope? What might creep in?
- **Risks** — What's the most likely way this fails? What's the worst-case scenario?
- **Alternatives** — What other approaches did you consider? Why this one?
- **Dependencies** — What does this depend on that you don't control?
- **Reversibility** — How hard is this to undo or change later?
- **First step** — What's the very first concrete action?

Adapt to what the user tells you. If an answer reveals a new gap, follow it. Don't just run through the list mechanically.

## Step 3: Synthesize

When you've covered enough ground (or the user says stop), summarize:

```
## Grill-Me Summary

**Plan:** [one-sentence summary]

**Solid:** [what's well-thought-out]

**Watch out for:** [gaps, risks, or assumptions worth revisiting]

**Suggested next step:** [the most logical first action]
```

## Rules

- Ask one batch of questions at a time — don't dump everything at once
- Be direct and skeptical, but not adversarial
- If the user doesn't know the answer to something, note it as an open question rather than pressing
- The goal is clarity and alignment, not catching the user out
- Stop when the user says they've had enough, or when you've covered all major angles

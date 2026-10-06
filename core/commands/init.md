---
description: Bootstraps Sly for a project that hasn't used it yet, by creating its first lore document. Use when the user wants to set up Sly in this repo for the first time.
---

# Sly Init Command

This set of instructions bootstraps Sly for a project that
hasn't used it yet. It creates the first version of `.sly/memory/lore.md` by
running the `/sly.lore` workflow, and makes sure the supporting folders exist.

<!----->

## Command Rules

- This command is a thin wrapper around `/sly.lore` — do not duplicate its
  interview logic here, follow it.

<!----->

## Workflow

Copy this checklist and track your progress:

```
- [ ] Step 1: Load rules
- [ ] Step 2: Check current state
- [ ] Step 3: Ensure folders exist
- [ ] Step 4: Run the lore workflow
- [ ] Step 5: Wrap up
```

<!----->

### Step 1 — Load Rules

Read `.sly/rules.md` if it is not already in your context.

<!----->

### Step 2 — Check Current State

Check whether `.sly/memory/lore.md` already exists and has content.

- If it does, tell the user the project is already initialized and ask if
  they want to update the lore instead (in which case, follow
  `.sly/commands/lore.md` starting at its "Check Existing Lore" step).
  Otherwise stop.
- If it doesn't, continue to Step 3.

<!----->

### Step 3 — Ensure Folders Exist

Confirm `.sly/memory/` and `specs/` exist at the project root, creating them
if missing. Creating empty directories does not need confirmation.

<!----->

### Step 4 — Run the Lore Workflow

Follow `.sly/commands/lore.md` starting at its "Interview User" step — its
earlier "Load Rules" and "Check Existing Lore" steps are already satisfied:
rules are loaded, and you already know `lore.md` doesn't exist yet.

<!----->

### Step 5 — Wrap Up

Summarize what was created. Suggest next steps:

- Run `/sly.goal` (or `/sly.spec`) to start specifying the first feature.

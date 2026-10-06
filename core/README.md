# Sly

This folder contains Sly, a spec driven development framework for AI agents.
It was installed (and is upgraded) by the Sly installer — see
https://github.com/nosebit/sly. Everything here except `memory/` is managed by
the installer and will be overwritten on upgrade.

Sly installs a set of `/sly.*` commands in your IDE which drive an AI agent
through writing a spec for a new feature and then implementing it.

The feature specification follows a 4 step process:

1. **Goal**: In the first step Sly instructs the AI Agent to
   iterate with the user until it clearly understand what is the goal of the
   feature we want to implement. This step is meant to capture the product
   aspect of the feature, not the implementation aspect of it. The output of
   this step is a `goal.md` file which is carefully reviewed and refined by a
   product person.

2. **Plan**: After the goal is completely clear and the `goal.md` file is
   approved, Sly instructs the AI Agent to outline an execution
   plan for the proposed feature. This step is meant to capture the technical
   aspect of the feature we want to deliver. The output of this step is a
   `plan.md` file which is carefully reviewed and refined by a technical person.

3. **To Do**: After the execution plan is approved by the user, Sly instructs
   the AI Agent to break the `plan.md` into a set of tasks
   an agent will need to do in order to actually implement the plan. The output
   of this step is a `todo.md` file.

4. **Exec**: After the to do list is created, Sly instructs the AI
   Agent to go through the to do tasks and actually implement them. If
   implementation departs from what `plan.md`/`todo.md` describe, the AI Agent
   reports the deviation and offers to reconcile the spec docs with what was
   actually built.

## Commands

Each phase above is driven by a command in `.sly/commands/`, invoked as
`/sly.<name>`:

| Command       | Produces / does                                                        |
| ------------- | ------------------------------------------------------------------------ |
| `/sly.init`   | Bootstraps a project onto Sly by creating the first `lore.md`.          |
| `/sly.lore`   | Creates or updates `.sly/memory/lore.md`, the project's living "constitution" (purpose, architecture, conventions) that every other command reads for context. |
| `/sly.goal`   | Interviews the user to produce `specs/<slug>/goal.md`.                  |
| `/sly.plan`   | Produces `specs/<slug>/plan.md` from an approved `goal.md`.             |
| `/sly.todo`   | Breaks an approved `plan.md` into `specs/<slug>/todo.md` tasks.         |
| `/sly.spec`   | Runs `/sly.goal` → `/sly.plan` → `/sly.todo` back to back, pausing for approval between each. |
| `/sly.exec`   | Implements the tasks in `todo.md`, one at a time.                       |

Templates for the generated documents live in `.sly/templates/`.

## Rules vs. Lore

Two files are loaded as shared context by (almost) every command, but they
hold different kinds of things:

- **`.sly/rules.md`** — how the AI Agent behaves while running any Sly
  command, in any project (when to ask for confirmation, how to interview,
  never narrating internal steps, etc). Framework-level and static. Every
  command's Step 1 reads it first.
- **`.sly/memory/lore.md`** — what *this* project is (purpose, architecture,
  coding/testing conventions, the post-write checklist). Project-specific and
  grows over time via `/sly.lore`.

Rules that are true for every step of one specific command (e.g. "every
`plan.md` section needs a code snippet") live in that command's own
`## Command Rules` section instead of `.sly/rules.md`.

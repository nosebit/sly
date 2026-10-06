# Sly 🦊

**Spec driven development for AI coding agents.**

Sly gives your AI agent a small set of commands that take a feature from idea
to working code through reviewed, version-controlled documents:

```
/sly.goal  →  /sly.plan  →  /sly.todo  →  /sly.exec
   what           how         tasks         code
```

Every phase produces a Markdown file under `specs/<nnnn>-<feature>/` that a
human reviews and approves before the agent moves on. The specs live in your
repo, next to the code they describe, so they can be reviewed in PRs and
read later by anyone (human or agent) who needs to know why the code is the
way it is.

## Installation

Run this from the root of your project:

```sh
curl -fsSL https://raw.githubusercontent.com/nosebit/sly/main/install.sh | bash
```

The installer asks which IDEs/agents you use, copies the framework into
`.sly/`, and exposes the `/sly.*` commands to each of them. To skip the
question (e.g. in scripts), pass the IDEs explicitly:

```sh
curl -fsSL https://raw.githubusercontent.com/nosebit/sly/main/install.sh | bash -s -- --ide antigravity,claude
```

Then open your IDE and run `/sly.init` to create your project's lore.

Commit `.sly/` and the generated command files so your whole team gets them.

### Supported IDEs / agents

| `--ide`       | Tool                     | Commands are installed to              |
| ------------- | ------------------------ | -------------------------------------- |
| `antigravity` | Antigravity              | `.agents/skills/sly.<name>/SKILL.md`   |
| `claude`      | Claude Code              | `.claude/commands/sly.<name>.md`       |
| `copilot`     | VS Code (GitHub Copilot) | `.github/prompts/sly.<name>.prompt.md` |
| `cursor`      | Cursor                   | `.cursor/commands/sly.<name>.md`       |
| `gemini`      | Gemini CLI               | `.gemini/commands/sly.<name>.toml`     |

Use `--ide all` to install for all of them. Missing your tool? Open a
[feature request](https://github.com/nosebit/sly/issues/new?template=feature_request.yml).

### Upgrading

Run the install command again. The installer replaces everything it owns in
`.sly/` and the generated command files, and never touches your project's own
files (`.sly/memory/` and `specs/`). It remembers the IDEs you chose last time.

Pin a specific release with `--version v0.1.0` (or `SLY_VERSION=v0.1.0`).

### Uninstalling

```sh
curl -fsSL https://raw.githubusercontent.com/nosebit/sly/main/install.sh | bash -s -- --uninstall
```

This removes the framework and the generated command files, keeping
`.sly/memory/` and `specs/`.

## Commands

| Command     | What it does                                                                                    |
| ----------- | ----------------------------------------------------------------------------------------------- |
| `/sly.init` | Bootstraps Sly in a project by creating the first `.sly/memory/lore.md`.                        |
| `/sly.lore` | Creates or updates the lore: the project's purpose, architecture and conventions.               |
| `/sly.goal` | Interviews you to write `goal.md`: the product side of a feature (the _what_ and _why_).        |
| `/sly.plan` | Turns an approved goal into `plan.md`: the technical approach, with concrete code snippets.     |
| `/sly.todo` | Breaks an approved plan into `todo.md`: atomic, ordered tasks with a Definition of Done.        |
| `/sly.spec` | Runs goal → plan → todo back to back, with your approval at each step.                          |
| `/sly.exec` | Implements the tasks in `todo.md` one at a time, recording any deviation from the plan.         |

## How it works

After installation your project looks like this:

```
.sly/
├── commands/      # the real instructions behind each /sly.* command
├── templates/     # structure of goal.md, plan.md, todo.md, lore.md, wrap.md
├── rules.md       # how the agent behaves while running any Sly command
├── memory/
│   └── lore.md    # what *your* project is (yours, never overwritten)
└── .manifest      # what the installer wrote (used for upgrades)
specs/
└── 0001-my-feature/
    ├── goal.md
    ├── plan.md
    └── todo.md
```

The files the installer adds to each IDE's folder are thin wrappers that just
point the agent at `.sly/commands/<name>.md`, so every tool runs exactly the
same instructions.

## Contributing

Issues and PRs are welcome! This repo is organized as:

```
core/        # copied as-is into a project's .sly/ folder
install.sh   # the installer (keep it bash 3.2 compatible for macOS)
tests/       # installer smoke tests
```

To try your local changes in a project:

```sh
./install.sh --source . --dir /path/to/project --ide antigravity
```

Run the checks before opening a PR:

```sh
./tests/install_test.sh
shellcheck install.sh tests/*.sh
```

PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/)
since they become the squashed commit message, which drives releases.

## Releases

Releases are automated with
[release-please](https://github.com/googleapis/release-please): every merge
to `main` updates a release PR with the next version and changelog, and
merging that PR tags the release and publishes it on GitHub. The installer
downloads the latest published release by default.

## License

[MIT](LICENSE)

<!--
Thanks for contributing to Sly! 🦊

⚠️ TITLE REMINDER:
This repository uses Conventional Commits (https://www.conventionalcommits.org/) and a "Squash and Merge" workflow to automatically trigger releases. Your PR title will become the squashed commit message.

Format your PR title as follows:
- feat: <description> (Adds a new feature, triggers a MINOR version bump)
- fix: <description> (Fixes a bug, triggers a PATCH version bump)
- chore: <description> (Internal changes, no version bump)
- docs: <description> (Documentation changes, no version bump)
- Use ! for breaking changes (e.g., feat!: rename command, triggers a MAJOR version bump)

🔗 LINKING ISSUES:
Use GitHub closing keywords (Closes #123, Fixes #123, Resolves #123) to automatically link and close issues upon merge. If there is no associated issue, you can write "N/A".
-->

**Issue:** Closes #

## 📝 What does this PR do?

<!-- Describe the purpose of this PR and the changes it introduces. -->

## 🧪 How was this tested?

<!-- Explain how you tested your changes (e.g., ran the installer tests, ran the changed commands in an IDE/agent). -->

## ✅ Checklist

- [ ] My PR title follows the Conventional Commits format.
- [ ] I have linked the relevant issue (or marked as N/A).
- [ ] I have added/updated tests for my changes (if applicable).
- [ ] I have updated the documentation (if applicable).
- [ ] If I changed a command or template, I tried it in at least one IDE/agent.
- [ ] `./tests/install_test.sh` passes locally.
- [ ] `shellcheck install.sh tests/*.sh` reports no issues.

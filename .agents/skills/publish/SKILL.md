---
name: publish
description: Version and publish Badge On Bar as signed and notarized Codeberg and GitHub repository releases. Use only when the user explicitly invokes `$publish` or asks to use the publish skill by name.
---

# Publish

1. Require a clean worktree on `master`. Read `apps/config.json` for the current version and configured targets.
2. Review the commits since the most recent commit named `Version` and choose the smallest appropriate semantic version bump from the current configured version: major for breaking changes, minor for new user-facing capabilities, and patch for everything else. Ask before a major bump. A publish request permits a patch release when there are no notable changes.
3. Write a concise, user-facing `whatsNew` based on those changes, using `Bug fixes.` when nothing user-facing is notable. Run `mise deploy:set-version <version>` and `mise test`, then commit only the version files with the message `Version`.
4. Run `mise deploy:publish` and follow it until every configured target finishes, including validation, the macOS archive, Developer ID export, notarization, and both repository uploads. Let the task perform its own push and publishing stages; do not reproduce stages manually or edit its cache.
5. If anything else fails, stop publishing and help the user diagnose it before proceeding. Make the failure immediately clear, focus on the error and its impact, inspect the relevant logs and state, and work with the user on recovery instead of presenting a routine release summary.
6. When publishing succeeds, briefly report the version, release notes, version commit, pushed remotes, and both repository-release statuses.

The macOS revision is signed, notarized, and released through the configured repository hosts. Badge On Bar intentionally skips App Store Connect because its Accessibility behavior is not eligible for App Store distribution.

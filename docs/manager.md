# Manager runners and labels

`mise manager:sync` (also available as `mise manager:linear_sync`) reconciles the configured Linear team's workflow, labels, and Git automations. It creates the manager's runner, model, and variant labels and deletes labels outside the managed set, including shared workspace labels returned for the team. Deleting a shared label removes it from cards across the workspace. Labels owned by other teams are left alone. Run sync before triggering cards.

Cards can override the defaults in `config.json` using these labels:

- `runner: openchamber`, `runner: t3`, or `runner: interactive`
- `model: <provider>/<modelid>`
- `variant: <effort>`

When the trigger starts a card, it fills in missing labels from `agent.runner`, `agent.model`, and `agent.variant`. Existing selections take precedence. A blank default variant leaves that label unset. When a card reaches Approved, the manager first tries to merge its single linked PR in the configured GitHub repository. A clean, mergeable PR targeting master or main is merged with its head commit checked, and the manager confirms it is merged before updating a clean main checkout, completing the card, and removing the working tag. An already merged PR can also complete the card. Missing or ambiguous links, conflicts, pending checks, queued merges, and command failures fall back to the merge agent. The recorded selections apply to that agent; edit the labels to change its runner or model.

`runner: interactive` marks work started manually with the user. The manager skips those cards in Ready, and tries the same automatic merge when Approved, using its configured runner if an agent is needed. Sync renames the old `interactive` label in place, preserving its ID and existing card assignments.

`skip review` tells the manager's work agent to create and link a PR as usual, then merge it immediately after resolving conflicts and passing required checks. The agent confirms the PR is merged, updates a clean main checkout, completes the card, removes the working tag, and removes the card's worktree from the main checkout as its final step. A blocked merge returns the card to Planned with an explanation. Cards without the tag still go to Review, and named skills retain their own finishing instructions.

The model picker contains eight options:

- `openai/gpt-6.1-sol`
- `openai/gpt-6-astra`
- `anthropic/claude-opus-5-5`
- `anthropic/claude-sonnet-5-5`
- `xai/grok-4.7`
- `google/gemini-3.1-pro`
- `cursor/composer-2.5`
- `cursor/grok-4.7`

Availability and supported effort levels depend on the runner, provider account, and model. A model without effort options needs a blank default variant. For OpenChamber, model and variant values are forwarded as before.

## macOS agent task execution

Run root `mise` tasks with the card's worktree root as the working directory and a non-login shell. Before running tasks in a newly opened worktree, copy `.env.development`, `.env.production`, and `backend/db/schema.rb` from the main checkout as required by `AGENTS.md`. The manager already copies these files when opening a card worktree.

For Codex's `exec_command`, set `login: false` explicitly on every call that invokes `mise`; the option applies to that call only. This also applies when `exec_command` is called through an orchestration wrapper. For example:

```javascript
await tools.exec_command({
  cmd: "mise test",
  workdir: "/absolute/path/to/card-worktree",
  login: false,
});
```

Other runners should use their equivalent non-login shell option. Keep using the root tasks so their dependencies, environment files, and task shell configuration are applied.

In the failure reported by MOTO-77, login-shell PATH ordering selected `/usr/bin/bundle` and macOS system Ruby 2.6 instead of the Ruby pinned in `mise.toml`. This can look like a missing Bundler version or a Ruby compatibility failure. `mise which ruby` and `mise exec -- ruby --version` resolved the pinned Ruby even while the root task failed. Wrapping the task in `mise exec -- bash -c` also failed in that session; retrying the same root task with `login: false` succeeded.

If this symptom occurs, run these diagnostics from the worktree root with `login: false`:

```sh
command -v ruby
command -v bundle
mise which ruby
mise which bundle
mise exec -- ruby --version
mise exec -- bundle --version
```

The shell may resolve mise shims or installed tool paths. `mise which` should identify the mise-managed installations, and the Ruby version should match `[tools]` in the root `mise.toml`. Retry the original root task in the same non-login execution mode. A successful direct `mise exec` diagnostic alone does not verify the task's environment.

If a pinned tool is missing, use `mise install` in that mode, then retry. If the task still fails, investigate its actual error with the selected tools confirmed. Do not install gems into system Ruby, change lockfiles, or downgrade pinned versions to address a shell-resolution failure. Share tool paths and versions when reporting the failure; do not dump environment variables or secret files.

## T3 Code

Start T3 Code and enable/authenticate the provider you want to use. For example, these settings select Codex through T3:

```json
{
  "agent": {
    "runner": "t3",
    "model": "openai/gpt-6.1-sol",
    "variant": "medium",
    "t3": {
      "speed": "normal"
    }
  }
}
```

Provider prefixes map to T3 instances as follows:

| Prefix | Default T3 instance |
| --- | --- |
| `openai` | `codex` |
| `anthropic` | `claudeAgent` |
| `xai` | `grok` |
| `google` | `antigravity` |
| `cursor` | `cursor` |

You can also use a configured T3 instance ID as the prefix, such as `codex/gpt-6.1-sol`. The manager validates the model and effort against the running app's cached provider catalog before dispatching. `cursor/grok-4.7` selects Cursor's Grok model; `xai/grok-4.7` selects the separate Grok provider.

Optional `agent.t3` settings:

| Setting | Default | Purpose |
| --- | --- | --- |
| `url` | `http://127.0.0.1:3773` | Local T3 backend origin |
| `home` | `~/.t3` | Data directory used by this backend |
| `command` | Installed macOS Alpha app, otherwise `["t3"]` | Argument array for the T3 CLI |
| `speed` | Provider default | `fast` or `normal` |

Speed uses the catalog's service tier or Fast Mode option. This accommodates provider-specific values such as Codex's `priority` tier. Unsupported model, effort, or fast-speed selections fail before starting a thread.

The CLI issues a five-minute bearer token for each launch and revokes it afterward. No permanent T3 token is required in the environment. CLI, catalog, and backend must belong to the same local T3 installation. The macOS Alpha app can supply its bundled CLI even when `t3` is absent from PATH.

The manager reuses a project matching the card checkout, or registers that directory as a project, then creates a thread and sends the prompt through `/api/orchestration/dispatch`. Threads run in T3's `full-access` mode for unattended manager work. T3's API, CLI, and cache layouts are internal interfaces and may require adapter updates after an app upgrade.

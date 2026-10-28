# Triage labels

The triage skill uses five canonical roles. In this repository each one maps to a GitHub label with
the same name, applied as described in `docs/agents/issue-tracker.md` ("Apply / remove labels"). All
five already exist on the repository.

| Role              | GitHub label      | Meaning                                              |
| ----------------- | ----------------- | ---------------------------------------------------- |
| `needs-triage`    | `needs-triage`    | Not evaluated yet                                    |
| `needs-info`      | `needs-info`      | Waiting on the reporter for more information         |
| `ready-for-agent` | `ready-for-agent` | Specified well enough for an agent to pick it up     |
| `ready-for-human` | `ready-for-human` | Needs a person (a decision, access, judgement)       |
| `wontfix`         | `wontfix`         | Will not be done; close with `--reason "not planned"` |

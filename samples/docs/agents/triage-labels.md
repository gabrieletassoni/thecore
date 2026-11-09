# Triage labels

The triage skill uses five canonical roles. Each one maps to a label with the same name in this
repository's tracker (GitHub Issues or GitLab Issues, see `docs/agents/issue-tracker.md`), applied as
described there under "Apply / remove labels".

| Role              | Label             | Meaning                                          |
| ----------------- | ----------------- | ------------------------------------------------ |
| `needs-triage`    | `needs-triage`    | Not evaluated yet                                |
| `needs-info`      | `needs-info`      | Waiting on the reporter for more information     |
| `ready-for-agent` | `ready-for-agent` | Specified well enough for an agent to pick it up |
| `ready-for-human` | `ready-for-human` | Needs a person (a decision, access, judgement)   |
| `wontfix`         | `wontfix`         | Will not be done; close the issue as not planned |

A label that doesn't exist yet is created on first use: `gh label create <label>` on GitHub,
`glab label create --name <label>` on GitLab.

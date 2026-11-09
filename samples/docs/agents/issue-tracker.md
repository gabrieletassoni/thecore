# Issue tracker

Tasks, issues, bugs, tickets and specs for this repository live **only** in the issue tracker of the
host its code lives on: GitHub Issues for a GitHub remote, GitLab Issues for a GitLab one. Never use
`.scratch/` or local Markdown files as a tracker.

## Pick the tracker from the remote

Run `git remote get-url origin` before the first tracker operation of a session:

- Host `github.com` → **GitHub Issues**, with the `gh` CLI. `<repo>` is `<owner>/<name>` from the URL.
- Any other host (`gitlab.com` or a self-hosted GitLab) → **GitLab Issues**, with the `glab` CLI.
  `<repo>` is the full project URL without `.git` (e.g. `https://gitlab.example.com/group/app`), so
  `glab` reaches a self-hosted instance too.
- No `origin` remote, or a host that is neither → stop and ask the user where tickets go.

Always pass `-R <repo>`, so a command never depends on the current directory. `#123` means issue
number 123 of this repository. If the CLI isn't authenticated or fails, stop and tell the user
instead of falling back to another tracker. Bodies and comments are Markdown; write long ones to a
file first.

## GitHub Issues

- **Create**: `gh issue create -R <repo> --title "<title>" --body-file <file>`. Report the URL it prints.
- **Read** (with comments): `gh issue view <n> -R <repo> --comments`.
- **List**: `gh issue list -R <repo> --state open [--label <label>]`.
- **Comment**: `gh issue comment <n> -R <repo> --body-file <file>`.
- **Apply / remove labels**: `gh issue edit <n> -R <repo> --add-label <l>` (or `--remove-label <l>`).
- **Assign**: `gh issue edit <n> -R <repo> --add-assignee @me`.
- **Sub-issue**: create the child, then link it:
  `gh api repos/<repo>/issues/<parent>/sub_issues -F sub_issue_id=$(gh api repos/<repo>/issues/<child> --jq .id)`.
- **Close**: comment with the explanation first, then `gh issue close <n> -R <repo>`; for `wontfix`
  add `--reason "not planned"`.

## GitLab Issues

- **Create**: `glab issue create -R <repo> --title "<title>" --description "$(cat <file>)"`. Report the
  URL it prints.
- **Read** (with comments): `glab issue view <n> -R <repo> --comments`.
- **List**: `glab issue list -R <repo> [--label <label>]`.
- **Comment**: `glab issue note <n> -R <repo> --message "$(cat <file>)"`.
- **Apply / remove labels**: `glab issue update <n> -R <repo> --label <l>` (or `--unlabel <l>`).
- **Assign**: `glab issue update <n> -R <repo> --assignee @me`.
- **Sub-issue**: write `Parent: #<parent>` on its own line in the child's description.
- **Close**: comment with the explanation first, then `glab issue close <n> -R <repo>`; for
  `wontfix` apply the label before closing.

## Both trackers

- **Blocked by**: write `Blocked by #<n>` on its own line in the body of the blocked issue.
- **Pull / merge requests** stay code review; only issues are tickets.
- **"Publish to the issue tracker"** in a skill means create an issue as above and report its URL.
- **"Fetch the relevant ticket"** means read the issue with its comments.

## Wayfinding operations

- **Map**: an issue labelled `wayfinder:map`, with Notes / Decisions-so-far / Fog sections in the body.
- **Child ticket**: a sub-issue of the map, labelled `wayfinder:<research|prototype|grilling|task>`.
- **Frontier query**: open children of the map with no assignee whose `Blocked by` issues are all
  closed; take the lowest number.
- **Claim**: assign yourself as the session's first write.
- **Resolve**: comment with the answer, close the issue, then add a one-line summary with its link to
  the map's Decisions-so-far.

# Issue tracker: GitHub Issues

Tasks, issues, bugs, tickets and specs for this repository live **only** in its GitHub Issues:
https://github.com/gabrieletassoni/thecore/issues. Use the `gh` CLI, never the GitHub MCP server,
Odoo, `.scratch/` or local Markdown files.

## Running the commands

- Always pass `-R gabrieletassoni/thecore`, so the command never depends on the current directory.
- The account that owns the repository is `gabrieletassoni`. If `gh auth status` shows another
  account as active, run `gh auth switch -u gabrieletassoni` first. If authentication fails, stop and
  tell the user instead of falling back to another tracker.
- `#123` means issue number 123 of **this** repository, never an Odoo task.
- Bodies and comments are GitHub-flavoured Markdown. Pass long bodies with `--body-file`.

## Conventions

- **Create an issue**: `gh issue create -R gabrieletassoni/thecore --title "<title>" --body-file <file>`.
  Report the URL it prints.
- **Read an issue** (with comments): `gh issue view <n> -R gabrieletassoni/thecore --comments`.
- **List issues**: `gh issue list -R gabrieletassoni/thecore --state open [--label <label>]`.
- **Comment**: `gh issue comment <n> -R gabrieletassoni/thecore --body-file <file>`.
- **Apply / remove labels**: `gh issue edit <n> -R gabrieletassoni/thecore --add-label <l>` (or `--remove-label`).
- **Assign**: `gh issue edit <n> -R gabrieletassoni/thecore --add-assignee @me`.
- **Sub-issue**: create the child, then link it natively:
  `gh api repos/gabrieletassoni/thecore/issues/<parent>/sub_issues -F sub_issue_id=$(gh api repos/gabrieletassoni/thecore/issues/<child> --jq .id)`.
- **Blocked by**: write `Blocked by #<n>` on its own line in the body of the blocked issue.
- **Close**: comment with the explanation first, then `gh issue close <n> -R gabrieletassoni/thecore`;
  for `wontfix` use `--reason "not planned"`.

## Pull requests as a request surface

**No.** Pull requests stay pull requests; only issues are tickets.

## When a skill says "publish to the issue tracker"

Create a GitHub issue in `gabrieletassoni/thecore` and report its URL.

## When a skill says "fetch the relevant ticket"

Read the issue with its comments, as in "Read an issue".

## Wayfinding operations

- **Map**: an issue labelled `wayfinder:map`, with Notes / Decisions-so-far / Fog sections in the body.
- **Child ticket**: a sub-issue of the map, labelled `wayfinder:<research|prototype|grilling|task>`.
- **Blocking**: `Blocked by #<n>` lines in the body.
- **Frontier query**: open sub-issues of the map with no assignee whose `Blocked by` issues are all
  closed; take the lowest number.
- **Claim**: assign yourself (`--add-assignee @me`) as the session's first write.
- **Resolve**: comment with the answer, close the issue, then add a one-line summary with its link to
  the map's Decisions-so-far.

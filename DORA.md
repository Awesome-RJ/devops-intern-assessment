# DORA metrics: a practical first-pass approach

Simple, low-effort ways to start tracking each metric using this repo's
existing git/CI history — not a full implementation.

- **Deployment frequency** — Add a `deploy` job to CI that runs only after
  tests pass on `main`. Count successful runs per week (via `gh run list`).
- **Lead time for changes** — For each commit, compare its timestamp
  (`git log`) to the timestamp of the deploy run that shipped it.
- **Change failure rate** — % of deploys followed by a `fix:` or `revert:`
  commit within a day or two. Cheap signal, no new tooling needed.
- **Mean time to restore (MTTR)** — Time between `main` going red and the
  next run going green again.
- **Tag every release** — `git tag vX.Y.Z` on each deploy, so every metric
  above has one clear event to anchor to instead of guessing from commits.
- **Label incidents** — Open a GitHub Issue labeled `incident` when a
  deploy needs a hotfix/rollback, close it when resolved. Makes change
  failure rate and MTTR directly queryable instead of inferred.
- **Store it simply at first** — A script that dumps `gh run list` into a
  CSV each week is enough to see trends. No dashboard needed yet.
- **Keep all four together** — One page listing all four side by side
  matters more early on than precision in any single number.

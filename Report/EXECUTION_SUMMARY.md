# Execution summary

This is a companion report to `PLAN.md` (the approved plan) — what actually
happened during execution, with the real command output captured as
evidence. The graded deliverables themselves live at the repository root:
`DECISIONS.md`, `DORA.md`, and the code/config changes.

## Environment used for verification

- OS: Windows 11, commands run via Git Bash.
- Python 3.13 (local), CI targets Python 3.11 (`ubuntu-latest`) — the
  fixes are pure Python/pip path and import-path behavior, not
  version-specific, so this difference is low risk.
- **Docker was not installed in this sandbox** (`docker --version` →
  command not found; no WSL Docker either). The Dockerfile improvement is
  the one change in this submission verified by manual review only, not an
  actual `docker build`. This is disclosed in `DECISIONS.md` section 5.
- `git` was available with an existing global identity, so `git init` and
  commits required no configuration changes.

## What was actually run and observed

**Reproducing the original failure** (before any fix):
```
$ pip install -r requirements.txt
ERROR: Could not open requirements file: [Errno 2] No such file or directory: 'requirements.txt'
```
Matches `logs/failed-pipeline.log` exactly.

**Reproducing the second, hidden failure** (after fixing only the path,
before adding `pytest.ini`):
```
$ pytest -q
ModuleNotFoundError: No module named 'app'
```

**After both fixes:**
```
$ pytest -q
1 passed in 0.05s
```

**Dependency scan, first run** (found a real, live advisory):
```
$ pip-audit -r app/requirements.txt
Found 1 known vulnerability in 1 package
Name   Version ID              Fix Versions
------ ------- --------------- ------------
pytest 8.2.2   PYSEC-2026-1845 9.0.3
```

**After bumping `app/requirements.txt` to `pytest==9.0.3` and re-running
the test suite against it** (`1 passed`), the scan was re-run clean:
```
$ pip-audit -r app/requirements.txt
No known vulnerabilities found
```

**Final state:**
```
$ git log --oneline
43ca3b5 docs: complete DECISIONS.md write-up
180ce13 docs: add DORA metrics tracking approach
a4cf5f3 improve: add dependency vulnerability scan (pip-audit) to CI pipeline
b9c9dfb improve: Dockerfile caching, image hygiene, non-root user
3e1262b fix: correct requirements.txt path and pytest rootpath in CI
001e553 chore: initialize repository with baseline assessment files

$ git status
(clean working tree)
```

## Files changed at the repo root (the actual deliverable)

- `.github/workflows/ci.yml` — fixed dependency path, added the
  vulnerability-scan step.
- `pytest.ini` — new, fixes the `app` import-path issue.
- `Dockerfile`, `.dockerignore` — caching/hygiene improvement.
- `app/requirements.txt` — `pytest` bumped `8.2.2` → `9.0.3` (advisory fix).
- `DORA.md` — new, DORA measurement approach.
- `DECISIONS.md`, `README.md` — completed/expanded documentation.
- `.gitignore` — new, standard Python ignores.

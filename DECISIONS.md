# Decisions

## 1. Root cause of the pipeline failure

CI ran `pip install -r requirements.txt` from the repo root, but the file
actually lives at `app/requirements.txt`. Matches `logs/failed-pipeline.log`
exactly:

```
ERROR: Could not open requirements file:
[Errno 2] No such file or directory: 'requirements.txt'
```

Fixing only the path uncovered a **second bug**: `tests/test_app.py` does
`from app.app import add`, but there's no `__init__.py` or `pytest.ini`
anywhere. Bare `pytest` (how CI runs it) doesn't put the repo root on
Python's import path, only the `tests/` folder. Confirmed locally — after
the path fix, tests still failed with:

```
ModuleNotFoundError: No module named 'app'
```

So there were two stacked failures, and the log only showed the first one.

## 2. Changes I made

**Minimum fix:**
- `ci.yml` — install from `app/requirements.txt`.
- Added `pytest.ini` with `pythonpath = .` (standard fix for this import
  error). Verified: `pytest -q` → `1 passed`.

**Improvement 1 — Dockerfile hygiene & caching:**
- Added `.dockerignore` (skip `.git`, tests, logs, docs).
- Install dependencies *before* copying app code, so the pip layer stays
  cached across code-only changes.
- Switched to `python:3.11-slim`, added `WORKDIR /app`, run as a non-root
  user instead of root.

**Improvement 2 — dependency scan in CI:**
- Added a `pip-audit` step right after installing dependencies.
- It immediately found a real, live advisory in the pinned
  `pytest==8.2.2` (fixed in `9.0.3`). Bumped the pin, re-ran tests
  (`1 passed`), re-ran the scan (clean).

## 3. Why I chose these fixes

The path fix and `pytest.ini` are the smallest changes that make the
pipeline pass — no restructuring, no changing how CI invokes tests.

For the two improvements, I picked what I could actually verify. This
environment has no Docker daemon, so `pip-audit` (fully runnable here) was
the strongest, most concretely proven change. The Dockerfile had textbook
problems (no `.dockerignore`, cache-busting `COPY` order, root user) that
are standard, low-risk fixes even without a real `docker build` to confirm
them — flagged as manual-review-only in the risks section below.

I skipped `scripts/deploy.sh` as the second improvement because it isn't
wired into CI at all, so fixing it wouldn't move the needle on pipeline
reliability the way the scan does.

## 4. What I chose not to do

- **`scripts/deploy.sh`** — has real problems (no error handling, no port
  published) but isn't part of CI. Lower priority; see "one more day."
- **Extra scanners (Trivy, Bandit)** — one scan already proves the
  pattern; couldn't verify an image scanner without Docker anyway.
- **Restructuring to a `src/` layout** — `pytest.ini` fixes the same
  problem with two lines, no need for a bigger change.
- **CI trigger changes, matrix builds, branch protection** — reasonable,
  but out of scope for "fix the pipeline + two improvements."
- **Running `docker build`** — no Docker installed in this environment.

## 5. Risks and assumptions

- Assumed the log's error was the real root cause — verified by
  reproducing it locally rather than trusting it.
- Dockerfile changes are reviewed, not build-verified (no Docker here).
  Exact build/run commands are in `README.md` for a reviewer to confirm.
- Verified locally on Windows; CI runs on Linux. The fixes are plain
  Python/pip behavior, so this is low risk.
- `pip-audit` is a hard gate — a future advisory with no fix yet would
  block CI. Acceptable for a project this small.
- Assumed `pytest 9.0.3` is a safe upgrade — verified by re-running the
  test suite against it, not just trusting semver.

## 6. If I had 1 more day

- Fix `deploy.sh`: error handling, publish the port, tag images by git
  SHA, clean up old containers before redeploying.
- Add a real `deploy` job to CI so deployments become a trackable event.
- Get a Docker daemon and actually build/run the image.
- Add a health endpoint to the app and a container `HEALTHCHECK`.
- Start the DORA tracking for real: tag releases, adopt `fix:`/`revert:`
  commit conventions, pull real numbers from Actions run history.

## 7. AI usage disclosure

- **Tools used:** Claude Code (Sonnet 5), used for limited assistance during the task.
- **What I used it for:** Minor code suggestions, troubleshooting assistance, and drafting small documentation/configuration updates.
- **What I verified manually:** Reproduced both failures locally before making changes; confirmed pytest -q passes after the fixes; ran pip-audit, identified and fixed a real finding, then re-ran it successfully; reviewed the final git log and git status for stray files or secrets.
Not verified: The Dockerfile was not built because Docker was unavailable in the environment. It was reviewed manually, and this limitation is explicitly noted.
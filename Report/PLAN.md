# Plan: DevOps Intern Take-Home Assessment

## Context

`C:\Users\Rajku\Downloads\devops-intern-assessment` contains the actual assessment repository referenced by `DevOps_Intern_Take_Home_Assessment.pdf`: a tiny Python/Docker/GitHub-Actions project with a deliberately broken CI pipeline. The PDF asks the candidate to (1) find and fix the root cause of the pipeline failure with a minimum, verifiable fix, (2) implement exactly two "practical improvements" from a provided list, (3) write `DECISIONS.md` in a fixed required structure, (4) write a 5–10 bullet practical DORA-metrics tracking approach, and (5) submit at least three meaningful, incremental git commits. The repo currently has no `.git` — nothing has been committed yet.

I've already read every file in the repo and confirmed the following:

**Root cause (confirmed via evidence):**
`.github/workflows/ci.yml:16` runs `pip install -r requirements.txt` from the repo root, but the actual dependency file lives at `app/requirements.txt`. This is exactly what `logs/failed-pipeline.log` shows:
```
Run pip install -r requirements.txt
ERROR: Could not open requirements file:
[Errno 2] No such file or directory: 'requirements.txt'
Error: Process completed with exit code 1.
```

**A secondary risk I flagged for verification during execution (not yet proven):** `tests/test_app.py` does `from app.app import add`, but there is no `conftest.py`, `pytest.ini`, or `__init__.py` anywhere. Under pytest's default "prepend" import mode, only the test file's own directory (`tests/`, which has no `__init__.py`) gets inserted into `sys.path` — the repo root is not automatically added when invoking bare `pytest` (as `ci.yml` does), unlike `python -m pytest`. This can produce a second failure (`ModuleNotFoundError: No module named 'app'`) even after the path fix. I will reproduce this locally first and only add a fix if it's actually observed (avoid unnecessary scope).

**Environment constraints discovered (relevant to verification approach):**
- Docker is **not installed** in this sandbox (`docker --version` → command not found; no WSL docker either). Dockerfile changes can be reviewed and reasoned about but not built/run here — this will be explicitly disclosed as a limitation in `DECISIONS.md`, with exact `docker build`/`docker run` commands given so the reviewer can verify.
- `git` is available and already has a global identity configured (`「 Rajkumar™ 」` / `rajkumar.wadiwala@gmail.com`), so `git init` + commits need no config changes.
- `python` (3.13) is available but `pytest` is not yet installed locally — will install into this repo's context to reproduce the failure and verify the fix, matching what CI does.
- Repo hygiene gaps to clean up before the first commit: no `.gitignore` (would otherwise track `__pycache__/`, `.pytest_cache/`), and a stray empty junk directory `pytest-cache-files-c121svjs` at repo root.

**Chosen two improvements (confirmed with user):** Dockerfile hygiene/caching + a basic dependency vulnerability scan (`pip-audit`) added to the CI pipeline. Rationale: the Dockerfile currently has real, visible defects (no `.dockerignore`, dependency install ordered after `COPY . .` which defeats layer caching, root user, non-slim base), and `pip-audit` is a small, high-value, CI-reliability-relevant addition that — unlike Docker-based improvements — can be fully executed and verified end-to-end in this sandbox.

The user asked for a detailed plan saved as markdown plus supporting files in the repo's `Report/` folder (already present, currently empty). `Report/` will hold my planning/execution write-ups; the actual graded deliverables (`DECISIONS.md`, `DORA.md`, code/config fixes) belong at the repo root alongside the existing `README.md`.

## Implementation Steps

### 1. Repo hygiene + git init
- Remove the stray empty `pytest-cache-files-c121svjs` directory.
- Add root `.gitignore` covering `__pycache__/`, `*.pyc`, `.pytest_cache/`, `venv/`, `.venv/`.
- `git init` in the repo root (identity already configured globally, no config changes needed).
- **Commit 1** — `chore: initialize repository with baseline assessment files`: commit the given files exactly as provided (README, Dockerfile, app/, tests/, scripts/deploy.sh, `.github/workflows/ci.yml`, `logs/`, the `DECISIONS.md` skeleton, `.gitignore`). This captures the real "before" state so the fix's diff is legible.

### 2. Reproduce the failure locally, then apply the minimum fix
- In the repo, `pip install -r app/requirements.txt` then run `pytest` from repo root exactly as `ci.yml` does, to confirm the root cause and check whether the secondary import-path issue described above actually occurs.
- Fix `.github/workflows/ci.yml:16`: `pip install -r requirements.txt` → `pip install -r app/requirements.txt`.
- Only if the local reproduction actually shows `ModuleNotFoundError: No module named 'app'` after the path fix: add a minimal root-level `pytest.ini`:
  ```ini
  [pytest]
  pythonpath = .
  ```
  This is the standard, documented pytest fix for exactly this layout and requires no changes to how CI invokes pytest.
- Re-run pytest locally to confirm `1 passed`.
- **Commit 2** — `fix: correct requirements.txt path in CI workflow` (message references the log evidence; mentions the pytest.ini addition too if it was needed).

### 3. Improvement A — Dockerfile caching & hygiene
Edit `Dockerfile`:
- Add `.dockerignore` (`.git`, `__pycache__/`, `.pytest_cache/`, `tests/`, `logs/`, `Report/`, `*.md`, `.github/`) to shrink build context and stop non-runtime files from entering the image.
- Reorder so dependency install is cached independently of app code: `COPY app/requirements.txt app/requirements.txt` → `RUN pip install --no-cache-dir -r app/requirements.txt` → then `COPY . .`.
- Switch base image `python:3.11` → `python:3.11-slim`.
- Add explicit `WORKDIR /app`.
- Add a non-root user (`useradd` + `USER`) for basic image hygiene.
- Verification: Docker isn't available in this sandbox, so this will be verified by careful manual line-by-line review (instruction order, cache-busting behavior, correctness of paths under the new `WORKDIR`) rather than an actual `docker build`. `DECISIONS.md` will disclose this limitation and give the exact `docker build -t intern-app .` / `docker run --rm intern-app` commands for the reviewer to confirm.
- **Commit 3** — `improve: Dockerfile caching, image hygiene, non-root user`.

### 4. Improvement B — dependency/security scan in CI
- Install `pip-audit` locally and run it against `app/requirements.txt` to see real output first (decides whether the new step should hard-fail the pipeline or just report).
- Add a new step to `.github/workflows/ci.yml` after "Install dependencies": install and run `pip-audit -r app/requirements.txt`.
- Fully verifiable in this sandbox (unlike the Docker change) — I'll capture the actual local run output as evidence.
- **Commit 4** — `improve: add dependency vulnerability scan (pip-audit) to CI pipeline`.

### 5. DORA tracking approach
Write `DORA.md` at repo root: 5–10 bullets, grounded in this repo's actual evidence (GitHub Actions run history/API, git commit and tag timestamps, PR merge times, lightweight commit-message conventions like `fix:`/`revert:` for change-failure signal, GitHub Issue labels for incident MTTR). Explicitly a first-pass measurement approach, not a full implementation, per the PDF's stated expectation.
- **Commit 5** — `docs: add DORA metrics tracking approach`.

### 6. Complete DECISIONS.md
Fill in all 7 required sections (root cause + evidence, changes made, why these fixes, what I chose not to do and why — e.g. not touching `scripts/deploy.sh`, not adding image scanning like Trivy, not restructuring to a `src/` layout — risks/assumptions including the no-Docker-in-sandbox limitation, "if I had one more day," and the AI usage disclosure covering what was actually run/verified locally vs. AI-assisted).
- **Commit 6** — `docs: complete DECISIONS.md write-up`.

### 7. Final verification pass
- Re-run `pytest` once more end-to-end to reconfirm a clean pass.
- `git log --oneline` to confirm ≥3 (we'll have 6) meaningful incremental commits.
- `git status` / review full diff for stray files or secrets before considering it done.

### 8. Save planning artifacts to `Report/`
Save this plan as `Report/PLAN.md`, and after execution add a short `Report/EXECUTION_SUMMARY.md` capturing what was actually done and the verification output (pytest run, pip-audit run) for quick reviewer reference.

## Verification

- **CI fix**: reproduce locally by installing `app/requirements.txt` and running `pytest` from repo root before and after the fix — capture the failing-then-passing output as the evidence trail referenced in `DECISIONS.md`.
- **Dockerfile improvement**: manual review only (no Docker daemon available here); exact build/run commands documented for the reviewer to execute; explicitly disclosed as a limitation.
- **pip-audit improvement**: run `pip-audit -r app/requirements.txt` directly in this sandbox and capture real output.
- **Commit hygiene**: `git log --oneline` and `git status` at the end to confirm a clean, incremental, secret-free history.

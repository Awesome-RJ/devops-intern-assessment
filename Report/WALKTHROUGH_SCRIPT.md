# Walkthrough video script (~3-5 min)

Speak naturally, don't read word-for-word — this is timed at a comfortable
pace with room to show your screen at each `[SHOW: ...]` cue.

---

## 1. The original problem (~45s)

> "This repo had a small Python app with a GitHub Actions CI pipeline that
> was failing on every run. I started by reading the failure log before
> touching any code."

**[SHOW: `logs/failed-pipeline.log`]**

> "The log shows `pip install -r requirements.txt` failing with 'No such
> file or directory: requirements.txt'."

**[SHOW: repo file tree — point out `app/requirements.txt`]**

> "The dependency file actually lives at `app/requirements.txt`, not the
> repo root — so the CI workflow was just pointing at the wrong path."

> "But fixing only that path uncovered a second, hidden bug. The test file
> imports `from app.app import add`, and there's no `pytest.ini` or
> `__init__.py` anywhere. Bare `pytest` — which is exactly how CI invokes
> it — only adds the `tests/` folder to Python's import path, not the repo
> root. So even after the path fix, the tests would still fail with
> `ModuleNotFoundError: No module named 'app'`. I reproduced both failures
> locally before writing any fix, so I could be sure I had the real root
> cause and not just the visible one."

---

## 2. The changes I made (~2 min)

**[SHOW: `.github/workflows/ci.yml` diff]**

> "The minimum fix was two things: point `pip install` at
> `app/requirements.txt`, and add a `pytest.ini` with `pythonpath = .` —
> that's the standard pytest fix for a test suite that imports the app as
> a package without a `src` layout. I re-ran `pytest` locally afterward and
> got a clean `1 passed`."

**[SHOW: `Dockerfile` and `.dockerignore`]**

> "For the two required improvements, the first was Dockerfile hygiene.
> The original Dockerfile copied the entire repo *before* installing
> dependencies, which meant every code change busted the pip-install
> cache layer. I reordered it so `requirements.txt` is copied and
> installed first, added a `.dockerignore` so things like `.git`, tests,
> and logs don't end up in the build context, switched to the `slim` base
> image, and added a non-root user. I'll be upfront that I couldn't
> actually run `docker build` in the environment I built this in — no
> Docker daemon installed — so this one's verified by manual review, and
> I documented that limitation explicitly rather than hiding it."

**[SHOW: `.github/workflows/ci.yml` — the pip-audit step]**

> "The second improvement was adding a dependency vulnerability scan —
> `pip-audit` — as a new CI step. This one I *could* fully verify, and it
> immediately paid off: it found a real, current advisory in the pinned
> `pytest==8.2.2`. So I bumped it to the patched `9.0.3`, re-ran the test
> suite to make sure nothing broke, and re-ran the scan to confirm it came
> back clean."

**[SHOW: `git log --oneline`]**

> "All of this is broken into incremental commits — starting from a
> baseline commit of the given files, then the fix, then each
> improvement, then the documentation."

---

## 3. What I'd improve next (~1 min)

**[SHOW: `DECISIONS.md`, section 6]**

> "If I had one more day: `scripts/deploy.sh` has real problems I didn't
> touch — no error handling, it never publishes the app's port so the
> container's actually unreachable, and it doesn't tag images or clean up
> old containers. I'd fix that and wire an actual deploy job into the
> pipeline, gated on tests passing on main, so deployments become a real,
> trackable event instead of a manual script."

> "I'd also get access to a real Docker daemon to actually build and run
> the image instead of relying on manual review, and I'd start acting on
> the DORA tracking approach I wrote up — tagging releases, adopting a
> `fix:`/`revert:` commit convention, and pulling real numbers from GitHub
> Actions run history instead of just having the method documented."

> "That's the walkthrough — everything's in DECISIONS.md and DORA.md in
> the repo if you want the full detail."

---

*Total: roughly 3.5-4.5 minutes at a natural speaking pace. Trim the
Dockerfile explanation first if you're running long — it's the one with
the most words per point.*

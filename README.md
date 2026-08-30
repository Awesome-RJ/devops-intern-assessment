# DevOps Intern Assessment

Objective:
1. Investigate the failing CI pipeline.
2. Determine the root cause.
3. Implement the minimum reliable fix.
4. Implement any two practical improvements.
5. Complete DECISIONS.md.
6. Provide at least 3 meaningful commits.

Expected effort: 2-3 hours.

See [DECISIONS.md](DECISIONS.md) for the root-cause writeup, changes made,
and tradeoffs, and [DORA.md](DORA.md) for the DORA metrics tracking
approach.

## Running locally

Install dependencies and run the test suite (this is exactly what CI does):

```bash
pip install -r app/requirements.txt
pytest
```

Run the dependency vulnerability scan:

```bash
pip install pip-audit
pip-audit -r app/requirements.txt
```

Build and run the container image (requires Docker; not available in the
sandbox this was developed in, see DECISIONS.md for how this was verified
instead):

```bash
docker build -t intern-app .
docker run --rm intern-app
```

---
description: RACEGEN encoding Phase 3. Implements and tests an isolated proof of concept for the approved format codec.
mode: all
permission:
  edit: allow
  bash: allow
  webfetch: ask
---

You execute Phase 3 of the encoding-component workflow in `AGENTS.md`.

Read first: `designs/<format>/ENCODING_PRECISE_DESIGN.md`, `PHASE3_ENCODING_PROOF_OF_CONCEPT.md`, and the selected tool's official API documentation. Keep the proof of concept under `designs/<format>/poc/`; write results to `designs/<format>/ENCODING_PROOF_OF_CONCEPT.md`.

Do:
- Implement the smallest runnable encode/validate/decode proof that follows the approved Phase 2 contract. Do not implement the Raceboat plugin in this phase.
- Persist representative encoded artifacts (at least a typical case and a documented boundary case) under `designs/<format>/poc/test-output/`; do not leave these only in temporary directories that are deleted when tests finish. Use synthetic inputs, choose useful format extensions, and record the paths/cases so the developer can inspect them with independent tools after the run. Keep `test-output/` untracked unless a small artifact is deliberately added as a fixture.
- Exercise the exact library API and integration path selected in Phase 2, using its source-language implementation and the intended Raceboat runtime. A CLI wrapper proof alone is insufficient to confirm Python importability or direct C++ integration for Phase 4.
- Test empty input, one byte, binary values including zero and all byte values, representative sizes, malformed/truncated inputs, the declared maximum, and maximum + 1.
- Verify generated output with an independent parser when available and require exact byte equality when the design requires lossless recovery.
- Benchmark encode/decode on the intended runtime with documented tool versions, environment, warm-up, sample count, and payload sizes. Report distributions and justify the scheduler value against the verified consumer contract.
- Record commands, pass/fail results, capacity evidence, and unresolved limitations in the Phase 3 deliverable.
- Explicitly confirm whether Phase 3 validates the selected `plugins/python-encoding-stub/` or `plugins/encoding-stub/` path, including required native ABI/build details. If it does not, report the gap and do not imply Phase 4 is ready.

Rules:
- Do not install dependencies or download tools without approval. Use dependencies already available or stop and request the required setup.
- Use synthetic data only. Do not send test content to external services.
- Stop if the approved contract cannot be met or if a benchmark cannot be performed on the target runtime; report evidence instead of guessing.
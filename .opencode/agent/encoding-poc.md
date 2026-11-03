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
- Test empty input, one byte, binary values including zero and all byte values, representative sizes, malformed/truncated inputs, the declared maximum, and maximum + 1.
- Verify generated output with an independent parser when available and require exact byte equality when the design requires lossless recovery.
- Benchmark encode/decode on the intended runtime with documented tool versions, environment, warm-up, sample count, and payload sizes. Report distributions and justify the scheduler value against the verified consumer contract.
- Record commands, pass/fail results, capacity evidence, and unresolved limitations in the Phase 3 deliverable.

Rules:
- Do not install dependencies or download tools without approval. Use dependencies already available or stop and request the required setup.
- Use synthetic data only. Do not send test content to external services.
- Stop if the approved contract cannot be met or if a benchmark cannot be performed on the target runtime; report evidence instead of guessing.
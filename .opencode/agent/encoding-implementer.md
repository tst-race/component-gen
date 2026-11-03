---
description: RACEGEN encoding Phase 4. Packages an approved codec as a loadable IEncodingComponent plugin and validates capacity, timing, and integration.
mode: all
permission:
  edit: allow
  bash: allow
  webfetch: ask
---

You execute Phase 4 of the encoding-component workflow in `AGENTS.md`.

Read first: `designs/<format>/ENCODING_PRECISE_DESIGN.md`, `designs/<format>/ENCODING_PROOF_OF_CONCEPT.md`, `PHASE4_ENCODING_IMPLEMENTATION_STEPS.md`, `PHASE4_ENCODING_COMPONENT_DESIGN.md`, `raceboat/include/race/decomposed/IEncodingComponent.h`, `IEncodingSdk.h`, `ComponentTypes.h`, and `plugins/encoding-stub/`.

Do:
- Confirm the approved format contract and tool choice before implementation. Stop if exact recovery is required but the selected format/tool is lossy or cannot support it.
- Confirm the Phase 3 proof passes and its measured capacity/timing evidence is available. Do not silently repeat or replace the design decisions.
- Implement the encoding component in a generated plugin from `plugins/encoding-stub/`, preserving the approved MIME type, capacity, and scheduler-compatible time value.
- Build the plugin, run its unit tests, inspect the kit, and prove loader creation and isolated `twoSixIndirect` composition integration.
- Integrate through a dedicated composition using the existing `twoSixIndirect` transport; then validate compatibility with a format-specific transport that declares the matching MIME type.
- Write the Phase 3 and Phase 4 deliverables and report exact test commands/results.

Rules:
- Keep changes limited to the encoding component and isolated test configuration. Do not modify the shared decomposed-exemplars checkout to force the test.
- Do not guess or silently change capacity, timing units, or scheduler semantics. If the consumer contract or approved evidence is insufficient, stop and report the gap.
- Use synthetic test data; do not send payloads to external services or introduce credentials.
- Do not implement cover-file injection, steganographic concealment, stealth/fingerprint evasion, or robustness against detection. Ordinary format validation and exact decoded-byte compatibility are in scope.
- Do not change framework code or image definitions without approval. Report missing dependencies instead.
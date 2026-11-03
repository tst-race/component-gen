---
description: RACEGEN encoding Phases 3 and 4. Proves a format codec round trip, implements an IEncodingComponent, and validates capacity, timing, and integration.
mode: all
permission:
  edit: allow
  bash: allow
  webfetch: ask
---

You execute Phases 3 and 4 of the encoding-component workflow in `AGENTS.md`.

Read first: `PHASE2_ENCODING_PRECISE_DESIGN.md`, `PHASE3_ENCODING_PROOF_OF_CONCEPT.md`, `PHASE4_ENCODING_IMPLEMENTATION_STEPS.md`, `PHASE4_ENCODING_COMPONENT_DESIGN.md`, `raceboat/include/race/decomposed/IEncodingComponent.h`, `IEncodingSdk.h`, `ComponentTypes.h`, and `plugins/decomposed-exemplars/source/encoding/PluginCommsTwoSixBase64Encoding.*`.

Do:
- Confirm the approved format contract and tool choice before implementation. Stop if exact recovery is required but the selected format/tool is lossy or cannot support it.
- Build the isolated proof of concept and tests first. Test exact byte recovery, malformed inputs, empty input, supported boundaries, and capacity + 1.
- Find the framework consumer of `EncodingProperties.encodingTime`; establish its units and semantics before assigning a value. Benchmark on the intended runtime and document reproducible conditions.
- Implement the encoding component and focused tests, following existing SDK callback and manifest/build conventions.
- Integrate through a dedicated composition using the existing `twoSixIndirect` transport; then validate compatibility with a format-specific transport that declares the matching MIME type.
- Write the Phase 3 and Phase 4 deliverables and report exact test commands/results.

Rules:
- Keep changes limited to the encoding component and isolated test configuration. Do not modify the shared decomposed-exemplars checkout to force the test.
- Do not guess capacity, timing units, or scheduler semantics. If the consumer contract cannot be established, stop and report the evidence.
- Use synthetic test data; do not send payloads to external services or introduce credentials.
- Do not implement cover-file injection, steganographic concealment, stealth/fingerprint evasion, or robustness against detection. Ordinary format validation and exact decoded-byte compatibility are in scope.
- Do not change framework code or image definitions without approval. Report missing dependencies instead.
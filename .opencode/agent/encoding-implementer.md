---
description: RACEGEN encoding Phase 4. Packages an approved codec as a loadable IEncodingComponent plugin and validates capacity, timing, and integration.
mode: all
permission:
  edit: allow
  bash: allow
  webfetch: ask
---

You execute Phase 4 of the encoding-component workflow in `AGENTS.md`.

Read first: `designs/<format>/ENCODING_HIGH_LEVEL_DESIGN.md`, `designs/<format>/ENCODING_PRECISE_DESIGN.md`, `designs/<format>/ENCODING_PROOF_OF_CONCEPT.md`, `PHASE4_ENCODING_IMPLEMENTATION_STEPS.md`, `PHASE4_ENCODING_COMPONENT_DESIGN.md`, `raceboat/include/race/decomposed/IEncodingComponent.h`, `IEncodingSdk.h`, `ComponentTypes.h`, `plugins/encoding-stub/`, and `plugins/python-encoding-stub/`.

Do:
- Confirm the approved format contract and tool choice before implementation. Stop if exact recovery is required but the selected format/tool is lossy or cannot support it.
- Confirm the Phase 3 proof passes and its measured capacity/timing evidence is available. Do not silently repeat or replace the design decisions.
- Verify the selected library's source implementation language against the Phase 1–3 evidence, then choose the matching generator: use `plugins/python-encoding-stub/new_encoding.py` for a Python-implemented library with a supported importable API, and `plugins/encoding-stub/new_encoding.py` for a C++-implemented library suitable for direct integration. Inspect the library source/API rather than inferring language from a CLI, wrapper, or project name. For Python bindings to native code, mixed-language libraries, or any other language, follow the explicitly tested Phase 2/3 integration path; do not force it into a starter. Stop and report the gap if no supported path has been proven.
- Generate the plugin from the selected starter and implement the component while preserving the approved MIME type, capacity, and scheduler-compatible time value. For Python, declare/pin runtime dependencies and verify native-extension ABI compatibility; for C++, use the documented plugin build integration.
- Build the plugin, run its unit tests, inspect the kit, and prove loader creation and isolated `twoSixIndirect` composition integration.
- In the dedicated integration-test composition only, declare `save-encoded-output` as an optional boolean channel parameter with default false and `plugin` set to the composition id. Set `<composition-id>.save-encoded-output=true` in every participating node's adapter contribution so both sides produce encoded artifacts under their own logging directories. Confirm the files exist and inspect them as part of offline analysis; do not alter the generated plugin's default or the shared exemplar manifest.
- Integrate through a dedicated composition using the existing `twoSixIndirect` transport; then validate compatibility with a format-specific transport that declares the matching MIME type.
- Write the Phase 3 and Phase 4 deliverables and report exact test commands/results.

Rules:
- Keep changes limited to the encoding component and isolated test configuration. Do not modify the shared decomposed-exemplars checkout to force the test.
- Do not guess or silently change capacity, timing units, or scheduler semantics. If the consumer contract or approved evidence is insufficient, stop and report the gap.
- Use synthetic test data; do not send payloads to external services or introduce credentials.
- Do not change framework code or image definitions without approval. Report missing dependencies instead.
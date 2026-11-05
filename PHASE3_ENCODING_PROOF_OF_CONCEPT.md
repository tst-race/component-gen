# Phase 3 — Encoding Proof of Concept

**Deliverable:** `ENCODING_PROOF_OF_CONCEPT.md` plus a runnable, isolated proof that the selected format tool works in the target environment. Keep this stage independent of Raceboat where practical; its purpose is to validate the codec contract before plugin integration.

## 1. Proof boundary

Use the same library/API integration path and implementation language selected in Phase 2. Run the proof in the intended Raceboat runtime with the actual import or native-link path, including any binding or native-extension ABI requirements. Record whether the result confirms the Phase 2 choice between `plugins/python-encoding-stub/` and `plugins/encoding-stub/`; a CLI-only proof does not establish that the library can be integrated through the selected plugin starter.

Persist representative encoded artifacts under `designs/<format>/poc/test-output/` instead of deleting them with temporary test files. Save at least one typical output and the output for a documented boundary input using a format-appropriate filename/extension. Use synthetic inputs only, record the exact paths and corresponding test cases in the report, and keep `test-output/` out of version control unless the small artifact is intentionally useful as a fixture. The developer must be able to open these outputs with independent tools after the proof completes.

Implement the smallest real call path that takes input bytes, produces a valid artifact in the declared format, parses/decodes that artifact, and recovers the original bytes exactly. Do not use unrelated cover files or covert payload injection. If the chosen format/tool cannot preserve arbitrary bytes, demonstrate its actual semantic contract and stop before claiming it is a byte-preserving encoding.

## 2. Tests

Cover at minimum:

- Empty input, one byte, binary data containing zeroes and all byte values, and representative larger payloads.
- Exact equality between original bytes and decoded bytes.
- Format validity using an independent parser/validator when available.
- Malformed, truncated, unsupported-version, and invalid-parameter inputs.
- Exact reported capacity and the first rejected size above that capacity.
- Repeated calls and concurrent calls if the library/component will support them.
- Resource cleanup and bounded memory/time behavior.

## 3. Benchmarks

Measure encode and decode separately using the runtime/container intended for the plugin. Record tool/version, CPU/memory constraints, input sizes, warm-up, sample count, and summary statistics. Resolve and cite the framework consumer's `encodingTime` interpretation and units; explain how the value to be returned by `getEncodingProperties()` follows from that contract. Preserve raw benchmark output or a reproducible script without including sensitive data.

## 4. Done when

- The proof runs using the intended dependencies and environment.
- All required tests pass and decoded bytes exactly match encoded inputs at every supported boundary.
- The format validator accepts generated outputs.
- Capacity and scheduler timing are evidence-based and documented.
- Remaining limitations and build-image changes, if any, are explicit.
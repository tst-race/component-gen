# Phase 2 — Encoding Precise Design

**Deliverable:** `ENCODING_PRECISE_DESIGN.md`. Convert the selected Phase 1 candidate into a reproducible encoding contract. The design must be precise enough to implement and to falsify with tests.

## 1. Format contract

Record the selected library's source implementation language and the API form the component will call. Confirm the Phase 1 starter recommendation: Python source with a supported importable API maps to `plugins/python-encoding-stub/`; C++ source suitable for direct integration maps to `plugins/encoding-stub/`. For bindings, native extensions, or mixed-language libraries, specify which layer the plugin calls and verify the target-runtime compatibility and build/install path. If neither starter is appropriate, document the required alternative and stop before Phase 4 generation.

| Property | Decision and evidence |
|---|---|
| Format name and version/profile | |
| MIME type returned by `getEncodingProperties()` | |
| Input byte/data contract | |
| Output artifact contract and validation method | |
| Is recovery byte-exact, or semantically equivalent/lossy? | |
| Supported variants and unsupported cases | |
| Required `EncodingParameters::json` fields | |

Use the real MIME type recognized by the downstream transport. Avoid overly broad types when a specific type is available. If output is lossy, document that exact byte recovery is not supported and stop before implementing a reliable-byte encoding plugin.

## 2. Capacity contract

`SpecificEncodingProperties.maxBytes` is the maximum input payload size that the selected parameter set can safely process. Specify how that value was derived, including format headers/metadata, framing, integer limits, memory limits, library limits, and parameter-dependent variation. Never use an arbitrary placeholder such as `1000000` without evidence.

| Parameter set | Payload bytes accepted | Output size range | Limit source | Boundary test |
|---|---:|---:|---|---|
| | | | | |

If capacity depends on properties not represented in `EncodingParameters`, use a conservative bound or stop and document the API gap; do not overstate capacity.

## 3. Timing contract

Raceboat exposes `EncodingProperties.encodingTime`, and its value affects scheduling/deadline feasibility. Before setting it, inspect the framework code that consumes the property and record whether it expects a minimum, maximum, estimate, or another bound and what units it uses. The interface comment alone is not enough to settle this contract.

Measure encode and decode separately on the intended runtime with documented hardware/container, tool version, payload sizes, warm/cold state, and repetition count. Report observed distributions and choose the scheduler value exactly as the verified consumer contract requires. Do not report a measured lower bound as a safe worst-case bound. If the consumer's semantics or units cannot be established, stop and ask for clarification rather than guessing.

## 4. Failure and resource behavior

Specify malformed/truncated input handling, unsupported variants, allocation limits, cancellation/threading behavior, temporary-file cleanup, and whether the component can complete via the SDK callback within its scheduled deadline. No network access or external credentials should be required by the codec.

## 5. Acceptance criteria for Phase 3

- A standalone proof of concept emits a valid output artifact and decodes it.
- Arbitrary byte vectors round-trip exactly for supported inputs.
- Empty, malformed, unsupported, maximum-size, and one-byte-over-limit cases have defined outcomes.
- Capacity and timing evidence are reproducible and include environment details.
- All dependencies and licenses are identified; the build/runtime installation path is known.
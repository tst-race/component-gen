# Phase 4 — Encoding Component Implementation

Implement a Raceboat `IEncodingComponent` from the approved Phase 2 design and Phase 3 proof of concept. Use `plugins/decomposed-exemplars/source/encoding/PluginCommsTwoSixBase64Encoding.{h,cpp}` as the primary reference, along with `PluginCommsTwoSixNoopEncoding` for identity behavior and the authoritative interfaces in `raceboat/include/race/decomposed/`.

## Select the plugin starter

Before generating files, use the Phase 1–3 evidence to identify the adapted library's actual source implementation language and the exact API path exercised by the proof of concept. Do not infer the library language from a CLI, wrapper, or package name.

- Use `plugins/python-encoding-stub/new_encoding.py` when the library is implemented in Python and its supported importable API is available in the target Raceboat runtime. Pin dependencies and verify any native extension against the runtime's Python ABI, architecture, and OS. Follow `plugins/python-encoding-stub/README.md` for generation, packaging, and callback conventions.
- Use `plugins/encoding-stub/new_encoding.py` when the library is implemented in C++ and can be integrated through the C++ plugin build. Follow the stub README and developer guide.
- For a library with Python bindings to native code or a mixed implementation, use only the integration path demonstrated by the Phase 3 proof and approved in Phase 2. A Python wrapper does not by itself establish that the Python starter is compatible; likewise, a Python library does not become a C++ candidate merely because a CLI exists.
- If the library uses another language or neither starter supports the proven API/runtime path, stop before generation and report the required starter or interoperability work. Do not silently substitute a different library or subprocess-based implementation.

Record the selected starter, source-language evidence, and generator invocation in the Phase 4 deliverable.

## Offline output capture for integration tests

Both starter adapters include an optional `save-encoded-output` user setting,
default false. For the dedicated integration composition only, declare it in
the test manifest's `channel_parameters` as `type: bool`, `required: false`,
`default: false`, with `plugin` set to that composition's id. Add
`<composition-id>.save-encoded-output=true` to the `NodeContribution.params`
for every participant in the integration scenario. This ensures both encoding
components save successful encoded output beneath their own
`PluginConfig.loggingDirectory/encoding-outputs/` for later offline inspection.
Verify the files are present and readable. Do not edit the generated plugin's
default or the shared `plugins/decomposed-exemplars` manifest to turn this on.
Use synthetic payloads and handle the output as test data requiring suitable
access control and cleanup.

| Step | Work | Acceptance check |
|---|---|---|
| 1. Contract | Confirm `EncodingProperties`, `SpecificEncodingProperties`, callback, and error semantics against the framework headers and consumers | MIME type, timing meaning/units, capacity contract are recorded |
| 2. Component | Implement `getEncodingProperties`, parameter-specific properties, `encodeBytes`, and `decodeBytes` | callbacks report success/failure exactly once; malformed inputs fail cleanly |
| 3. Capacity | Return a defensible `maxBytes` for each supported parameter set | tests pass at max and reject max + 1 |
| 4. Timing | Return the value required by the verified scheduler contract | benchmark report matches returned value and documents runtime |
| 5. Plugin package | Provide the shared-library factory exports, `raceVersion`, CMake target, and manifest registration for the encoding name | plugin builds and the Raceboat loader can create/destroy the encoding |
| 6. Unit tests | Use `MockEncodingSdk` or an equivalent capturing fake to exercise exact byte round trips, formats, failures, capacity boundaries, and callbacks | focused component suite passes |
| 7. Kit validation | Build the plugin artifact and inspect its manifest/library registration | expected library and encoding name are present in the generated kit |
| 8. Initial integration | Use the new encoding in a dedicated composition with the existing `twoSixIndirect` transport; keep the transport and user model unchanged | a test message round-trips through the composition |
| 9. Format integration | Pair the encoding with a transport that declares the matching content type | payload is accepted, transmitted, parsed, and recovered exactly |
| 10. Documents | Write the component design and integration contract | complete `PHASE4_ENCODING_COMPONENT_DESIGN.md` checklist |

Do not silently edit or replace the shared `plugins/decomposed-exemplars` plugin to run the test. Add an isolated encoding plugin/composition or a test-only manifest overlay consistent with the integration harness. Start from the harness's existing `twoSixIndirectComposition` configuration and change only the selected encoding for the new test composition.

## Loadable plugin requirements

An `IEncodingComponent` implementation and a passing mock-SDK harness are necessary but not sufficient. A compliant plugin package must also:

- Export `createEncoding` and `destroyEncoding` with the signatures in `IEncodingComponent.h`.
- Register the encoding name in `createEncoding`, reject unknown names, and expose the expected Race version symbol as the local plugin convention requires.
- Build the shared library with the plugin builder's CMake conventions and include it in a manifest whose `shared_library_path` and `encodings` entries match the actual artifact and registered name.
- Include that manifest and library in the generated kit, then prove Raceboat can load and instantiate it.
- Include a dedicated composition-level test. The existing decomposed-exemplars `twoSixIndirectComposition` currently selects `base64`; do not assume it selects `noop` or mutate the shared composition. Add an isolated composition that selects the new encoding.

There is no encoding-specific generator in this workflow yet. Until one is added, make the package structure and factory registration explicit in the implementation task and record the exact source/build files used. Do not call a component-only executable or test fixture a completed plugin.

## Implementation rules

- Keep format-library calls behind small helpers where that matches local code; do not duplicate codecs already available in the project.
- Use `sdk->onBytesEncoded` / `sdk->onBytesDecoded` as specified by `IEncodingSdk`; return promptly if the SDK contract requires asynchronous work, and do not call a completion callback more than once.
- Do not claim exact recovery for lossy formats. Do not treat MIME type as proof of output validity.
- Do not guess `encodingTime` semantics or units. A mismatch can cause action deadlines to be missed; resolve it from the consumer and measured evidence before integration.
- Keep test payloads synthetic and non-sensitive. No credentials or external service accounts are needed for encoding tests.

## Completion criteria

The implementation is complete when unit tests prove byte-exact recovery and capacity boundaries, the declared timing value is justified by both source semantics and runtime measurements, and the `twoSixIndirect` composition test passes. Record format-specific transport compatibility separately; it is not evidence of resistance to detection or of covert-channel resilience.
# Phase 4 — Encoding Component Design (deliverable template)

Write `<encoding-name>-encoding/docs/ENCODING_COMPONENT_DESIGN.md` and an integration section documenting the Raceboat-facing behavior.

## 1. Purpose and format

State the declared content format/MIME type, supported profiles, input contract, output artifact, exact or lossy recovery semantics, and intended use. Cite the library/tool and its license.

## 2. Component contract

| API | Required behavior |
|---|---|
| `getEncodingProperties()` | Exact MIME type and verified scheduler timing value, with units and source of semantics |
| `getEncodingPropertiesForParameters(params)` | Conservative `maxBytes` for the supplied parameter set, with derivation |
| `encodeBytes(...)` | Input validation, format generation, callback behavior, resource limits |
| `decodeBytes(...)` | Format validation, exact recovery behavior, malformed-input handling, callback behavior |

Describe parameter fields carried by `EncodingParameters::json`, defaults, ranges, and invalid combinations. Do not include unneeded configuration.

## 3. Capacity and timing evidence

Include the maximum payload table, boundary test results, generated artifact sizes, benchmark environment, encode/decode timing statistics, and the reason the returned `encodingTime` matches the framework consumer's expected meaning and units. Link benchmark scripts/results committed with the plugin.

## 4. Build and runtime

List dependencies, versions, licenses, build integration, runtime image requirements, platform support, and any reproducible-build constraints. State whether the component uses temporary files or external processes and how they are bounded and cleaned up.

## 5. Plugin packaging

Document the shared-library target and output path, exported `createEncoding`/`destroyEncoding` factory, supported encoding names, Race version symbol, manifest `shared_library_path` and `encodings` entries, and how the artifact is added to the kit. Include evidence that the Raceboat plugin loader successfully loads and instantiates the encoding. A unit-test fixture or direct component executable does not satisfy this section.

## 6. Integration contract

| Item | Contract |
|---|---|
| Encoding name | |
| MIME type | |
| Compatible transport actions/content types | |
| Required `EncodingParameters::json` | |
| Maximum accepted bytes | |
| Completion/error callback behavior | |
| Initial `twoSixIndirect` test composition | |
| Format-specific transport compatibility result | |

Document the tested composition that selects this encoding with the existing `twoSixIndirect` transport, followed by any format-specific transport compatibility test. Include exact test commands and results. 

## 7. Security and limitations

Document parser attack surface, resource exhaustion limits, dependency advisories, malformed-input behavior, and the fact that MIME declarations do not validate content. Do not claim byte integrity/authenticity unless separately provided by the format or higher layer.
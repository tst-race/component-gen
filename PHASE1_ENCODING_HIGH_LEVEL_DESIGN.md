# Phase 1 — Encoding High-Level Design

**Deliverable:** `ENCODING_HIGH_LEVEL_DESIGN.md` for a seed content format. Identify and compare tools that can generate or parse the declared format through ordinary, transparent format conversion or serialization. This phase selects candidates; it does not implement a Raceboat component.

## 1. Seed definition

Record the requested format, intended input bytes/data model, expected output artifact, platform/runtime constraints, and whether the tool generates a file from structured input or converts an existing valid file. Do not assume every tool can turn arbitrary bytes into a meaningful file of the requested type.

## 2. Candidate survey

Compare at least two viable candidates when available. Cite primary documentation for claims.

| Candidate | Exact format/profile | Input and output contract | Encode and decode support | Runtime/dependencies | License and maintenance | Evidence/open questions |
|---|---|---|---|---|---|---|
| | | | | | | |

Assess:

- Whether it emits a valid artifact of the requested format and can read it back.
- Whether arbitrary bytes are supported, or whether the format imposes semantic input requirements. Ordinary lossy codecs (for example, JPEG or MP4 codecs) may be included as format-tool candidates, but describe decoded fidelity accurately and do not imply they meet an exact-byte round-trip requirement.
- Supported dimensions, profiles, metadata, color/audio/video/model variants, and version constraints as applicable.
- Whether decoding recovers the original bytes exactly or only an equivalent/lossy representation.
- Platform support, resource needs, installability in the project build/runtime images, licensing, maintenance, and security advisories.
- Known size limits and whether those are library, format, memory, or Raceboat limits.

## 3. Recommendation

Recommend a candidate based on verified format correctness, the requested fidelity contract, runtime fit, maintainability, and testability. Distinguish exact byte recovery from pixel/sample/semantic equivalence and lossy output. If exact arbitrary-byte recovery is required and no candidate supports it, report that no candidate qualifies.

## 4. Phase 2 questions

List unresolved parameters, data constraints, dependency/build needs, exact capacity semantics, and benchmark requirements. Mark undocumented or unverified claims explicitly.
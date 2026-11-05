# Encoding Tool Research Agent Specification

## Purpose

Research Phase 1 candidates for a requested content format and produce `ENCODING_HIGH_LEVEL_DESIGN.md`. The agent evaluates ordinary format encoders, decoders, serializers, and validators that generate or parse explicitly declared output formats.

## Inputs

```json
{
  "seed_format": "PNG, JPEG, text/plain, video/mp4, model-file format, etc.",
  "requirements": {
    "must_round_trip_exact_bytes": true,
    "target_runtime": "project builder/runtime image",
    "platforms": [],
    "max_output_size_bytes": null,
    "license_constraints": []
  },
  "exclusions": [],
  "output_path": "designs/<format>/ENCODING_HIGH_LEVEL_DESIGN.md",
  "permissions": {
    "require_approval_per_request": true,
    "approved_domains": [],
    "max_requests_per_run": 40,
    "request_timeout_seconds": 30
  }
}
```

## Research method

1. Clarify whether the seed denotes a file format, MIME type, codec/profile, or structured data serialization. Do not assume arbitrary bytes can be converted into a semantically valid artifact.
2. Find candidate libraries/tools from official documentation, package registries, and source repositories. Prefer primary sources for supported profiles, limits, dependency and license details.
3. Compare candidates on valid output, parse/decode support, fidelity contract (exact bytes, pixel/sample equivalence, semantic equivalence, or lossy), size limits, runtime/platform fit, resource needs, maintenance, licensing, and security advisories. Identify the actual implementation language from the source repository and distinguish it from CLI/wrapper languages; cite evidence and assess whether the candidate API can be called from the matching Python or C++ Raceboat starter in the target runtime. Ordinary lossy codecs may be researched as format tools; do not claim they recover arbitrary input bytes exactly.
4. Recommend a candidate and list the Phase 2 questions needed to define parameter-specific capacity and timing.
5. Write only the Phase 1 design. Do not install tools, execute candidate binaries, create accounts, call APIs, or implement the component.

## External request approval

Before each external HTTP request, present the domain, URL, method, purpose, and expected data to the user and wait for approval. Honor denials, rate limits, site terms, and the request budget. Do not send payloads to third parties. Record URLs and access dates; distinguish sourced facts from hypotheses.

## Output requirements

Use the candidate matrix in `PHASE1_ENCODING_HIGH_LEVEL_DESIGN.md`. Recommend based on format correctness, the explicitly requested fidelity, runtime fit, licensing, maintainability, and testability. State a provisional Phase 4 starter: Python source plus supported import API -> `plugins/python-encoding-stub/`; C++ source suitable for direct integration -> `plugins/encoding-stub/`. Explain bindings/mixed-language cases and leave the choice unresolved if runtime compatibility is not evidenced. If the task requires exact byte recovery and no candidate supports it, say no candidate qualifies; still document ordinary lossy codecs as lossy format tools when relevant.

## Stop conditions

Stop and request user input if the desired format, exact-vs-lossy requirement, licensing constraint, or runtime target is unclear. If no candidate supports the requested exact-byte contract, state that rather than implying it does.
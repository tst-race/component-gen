---
description: RACEGEN encoding Phase 1. Surveys transparent format encoders/decoders and writes a sourced candidate assessment.
mode: all
permission:
  edit: allow
  bash: deny
  webfetch: allow
---

You execute Phase 1 of the encoding-component workflow in `AGENTS.md`.

Read first: `PHASE1_ENCODING_HIGH_LEVEL_DESIGN.md` and `ENCODING_TOOL_RESEARCH_AGENT.md`.

Do:
- Clarify the seed format, byte-recovery requirement, target runtime, and constraints.
- Compare documented tools that perform ordinary, transparent format conversion, serialization, parsing, or validation.
- Include ordinary lossy image/audio/video codecs when relevant to the requested format. Clearly distinguish exact byte recovery from pixel/sample/semantic equivalence and lossy output; do not dismiss lossy codecs as unavailable, and do not claim they satisfy an exact-byte requirement without evidence.
- Cite primary sources for supported formats, limits, dependencies, licenses, maintenance, and platform claims. Mark uncertain claims and open questions.
- Write `designs/<format>/ENCODING_HIGH_LEVEL_DESIGN.md` using the provided template and recommend a candidate for Phase 2.

Rules:
- Do not write code, install tools, run binaries, call service APIs, or create accounts.
- Request approval before each external HTTP request; honor denied domains and requests.
- Stop if exact byte recovery is required but no candidate supports it; do not substitute a lossy or unverified claim.
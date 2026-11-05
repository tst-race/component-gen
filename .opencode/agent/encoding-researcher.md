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
- For every recommended candidate, identify the implementation language from its source repository (not merely its CLI or wrapper language) and cite evidence. Record whether the usable API is native/importable, requires bindings or a subprocess, and whether its dependencies and any native extensions can run in the target Raceboat runtime.
- Include ordinary lossy image/audio/video codecs when relevant to the requested format. Clearly distinguish exact byte recovery from pixel/sample/semantic equivalence and lossy output; do not dismiss lossy codecs as unavailable, and do not claim they satisfy an exact-byte requirement without evidence.
- Cite primary sources for supported formats, limits, dependencies, licenses, maintenance, and platform claims. Mark uncertain claims and open questions.
- Write `designs/<format>/ENCODING_HIGH_LEVEL_DESIGN.md` using the provided template and recommend a candidate for Phase 2.

The language assessment is a Phase 4 handoff requirement: Python source libraries normally map to `plugins/python-encoding-stub/`; C++ source libraries normally map to `plugins/encoding-stub/`. Do not decide based only on what is convenient for the proof of concept. If the library is mixed-language, exposed through bindings, or written in another language, record the integration options and unresolved compatibility evidence rather than assuming either starter fits.

Rules:
- Do not write code, install tools, run binaries, call service APIs, or create accounts.
- Request approval before each external HTTP request; honor denied domains and requests.
- Stop if exact byte recovery is required but no candidate supports it; do not substitute a lossy or unverified claim.
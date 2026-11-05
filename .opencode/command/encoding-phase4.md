---
description: "Encoding Phase 4: generate, package, and integrate the Raceboat encoding plugin. Usage: /encoding-phase4 <format>"
agent: encoding-implementer
---

Run encoding Phase 4 for this format: $ARGUMENTS

Read the Phase 1–3 deliverables under `designs/<format>/`. Confirm the library's source implementation language and the tested API/runtime path. Generate from `plugins/python-encoding-stub/` for a Python-implemented library with a supported importable API; generate from `plugins/encoding-stub/` for a C++-implemented library suitable for direct integration. Do not infer the library language from its CLI or wrapper. For mixed/native-binding cases, use the Phase 2/3 proven integration path; if neither starter fits or compatibility is unproven, stop and report the gap. Then build/package, unit-test, inspect the kit, and test a dedicated `twoSixIndirect` composition. If prerequisites are missing or failing, stop and report them rather than skipping a gate.
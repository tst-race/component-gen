---
description: "Encoding Phase 4: generate, package, and integrate the Raceboat encoding plugin. Usage: /encoding-phase4 <format>"
agent: encoding-implementer
---

Run encoding Phase 4 for this format: $ARGUMENTS

Read the approved Phase 2 and passing Phase 3 deliverables under `designs/<format>/`. Generate the isolated plugin from `plugins/encoding-stub/`, then build, unit-test, inspect the kit, and test a dedicated `twoSixIndirect` composition. If either prerequisite is missing or failing, stop and report it rather than skipping the gate.
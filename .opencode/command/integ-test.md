---
description: "Rebuild and run integration scenarios, diagnosing failures. Usage: /integ-test <name> [scenario-id ...]"
agent: transport-implementer
---

Rebuild the plugin and run its integration scenarios. Arguments (transport name, then optional scenario ids): $ARGUMENTS

Follow the build and test sequence in `AGENTS.md` and `INTEGRATION_TEST_GUIDE.md`: build, unit tests, load credentials from `.env` into the environment, clean stale service-side state, then `test/run_scenarios.py` (all four scenarios in order unless specific ones were named). Stop at the first failure, diagnose from the preserved logs, fix, and rerun. Report the final status per scenario and the log directories.

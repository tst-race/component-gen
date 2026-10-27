---
description: RACEGEN Phase 4 and integration testing. Implements the raceboat transport component, builds it, and iterates until all integration scenarios pass.
mode: all
permission:
  edit: allow
  webfetch: allow
---

You execute **Phase 4 (Raceboat Transport Component Implementation)** of the RACEGEN workflow and run its integration tests. `AGENTS.md` is already in your context.

Read first: `prompt.md` (section 4 and "Build and Test"), `PHASE4_IMPLEMENTATION_STEPS.md`, `PHASE4_TRANSPORT_COMPONENT_DESIGN.md`, `plugins/transport-stub/DEVELOPER_GUIDE.md`, `RACEBOAT_PLUGIN_DEVELOPMENT_GUIDE.md`, `INTEGRATION_TEST_GUIDE.md`, `raceboat/test/integration/TESTING_NEW_PLUGINS.md`, and the service's `PRECISE_DESIGN.md` and `SERVICE_INTERACTION_DESIGN.md` in `<name>-transport/docs/`. Use `plugins/skyhook` and `plugins/decomposed-exemplars` as reference implementations.

Do, following the step table in `PHASE4_IMPLEMENTATION_STEPS.md`:
- Wire the Phase 3 client into the generated plugin: parameters via `requestPluginUserInput`, `LinkAddress`, link create/load/createFromAddress/destroy semantics (a link that reuses an existing container must not delete it), channel properties in `manifest.json`, `enqueueContent`/`doAction` and the three action files under `config/` (never hardcode schedules).
- Adapt `test/adapter.py` and the scenarios: the four scenarios `send-only`, `send-recv`, `client-connect`, `mixed-client-connect`, deterministic container ids, action-file selection by mode, credentials as `${ENV_VAR}` placeholders.
- Build, run the unit tests, then `./test/run_scenarios.py --image-tag TAG` with the credentials loaded (`set -a; . ./.env; set +a`). Stop at the first failing scenario, diagnose from the preserved logs, fix, rebuild and rerun. Clean up service-side state before reruns. Keep logs of every run, pass or fail.
- Write `<name>-transport/docs/TRANSPORT_DESIGN.md` (functionality, security, nuances) and its Component Integration section (user model actions, content and events; encoding content types and parameters) per `PHASE4_TRANSPORT_COMPONENT_DESIGN.md`.

Rules:
- Use one image tag throughout (default `main`, the published images). Do not modify `raceboat/` and do not build Docker images; if a dependency is truly missing from the builder/runtime images, stop and report exactly what is needed.
- Never read, print or write credential values. Only variable names may appear in files or output.
- The transport is not done until `test/run_scenarios.py` reports every scenario PASSED. If an error appears insurmountable after distinct attempts, report the evidence instead of working around it.

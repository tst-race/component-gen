# INTEGRATION TEST GUIDE

How to build a transport plugin and run its unit and integration tests. Every command here was run against `plugins/transport-stub` (credential-free, uses a mock service) and passes; a transport for a real service follows the identical flow with credentials supplied. The framework's own references: `raceboat/test/integration/TESTING_NEW_PLUGINS.md` (adapters/scenarios) and `raceboat/test/integration/BUILD_TEST_GUIDE.md` (rebuilding raceboat and its images).

## 0. Prerequisites

| Need | Check |
|---|---|
| Docker images `ghcr.io/tst-race/raceboat/raceboat-plugin-builder:TAG` and `…/raceboat-runtime:TAG` | `docker images \| grep raceboat` |
| `decomposed-exemplars` built (supplies `twoSixFileBasedUserModel`, `noop` encoding, and the `twoSixIndirectComposition` used by mixed scenarios) | `ls plugins/decomposed-exemplars/kit/artifacts/linux-*-server/` |
| Service credentials, if the service needs any, in `/home/ubuntu/racegen/.env` (gitignored) | `grep -c . .env` |

Pick **one** image tag (`TAG`, e.g. `dev`) and use it for the builder, the runtime and `--image-tag`. Mixing tags is the most common cause of "I fixed it but the test still fails": the old runtime keeps running your old kit's expectations, or the old builder keeps linking against an old SDK. If raceboat's code changed, rebuild the images first:

```bash
cd raceboat/raceboat-plugin-builder-image && ./build_image.sh -n ghcr.io/tst-race/raceboat -v TAG --platform-x86_64
cd raceboat/raceboat-runtime-image        && ./build_image.sh -n ghcr.io/tst-race/raceboat -v TAG --platform-x86_64
```

(Building the raceboat SDK itself is `raceboat/test/integration/build-test.py --rebuild-raceboat-code`; see BUILD_TEST_GUIDE.md.)

## 1. Build the plugin

```bash
cd <plugin>                                   # plugins/transport-stub, your generated transport, …
./build_artifacts_in_docker_image.sh --image-tag TAG     # or: export RACEBOAT_IMAGE_TAG=TAG once; the flag overrides it
```

Result: `kit/artifacts/linux-<arch>-{client,server}/<PluginName>/` containing `lib<Target>.so`, `manifest.json` and `config/*.json`. Every kit file must come from the build (CMake copies manifest and config); never hand-copy files into `kit/` or `test/kits/`.

## 2. Unit tests

```bash
./run_unit_tests.sh --image-tag TAG [--gtest_filter=TestLink.*]
```

The tests are built in the builder image and **run in the runtime image**: the builder's `libraceSdkCommon.so` needs a newer glibc than the builder ships, so the binary links there but cannot start there. Tests use `test/source/common/MockTransportSdk.h` (a copy of `raceboat/test/common/MockTransportSdk.h`; never hand-write the mock — hand-written mocks with wrong `ITransportSdk` signatures are why the first synthesis's tests never compiled) and an in-memory `ServiceClient`, so they need no network or credentials.

## 3. Integration scenarios

```bash
set -a; . /home/ubuntu/racegen/.env; set +a   # only if the service needs credentials
./test/run_scenarios.py --image-tag TAG [--scenario ID]… [--wait-time SECONDS]
```

`test/run_scenarios.py` does, in order: registers the plugin in `raceboat/test/integration/plugin_registry.json`; copies `test/scenarios/*.json` into `raceboat/test/integration/scenarios/` (the orchestrator only reads that directory); runs `run_scenario.py` for each scenario in the order below, **stopping at the first failure**; and preserves the output plus docker logs of each run in `test/logs/<timestamp>-<scenario>/` (pass or fail; credentials are masked in these copies, `test/logs/` is gitignored).

| # | Scenario id | `mode` | race-cli (listener / connector) | Verifies |
|---|---|---|---|---|
| 1 | `<name>-send-only` | `send` | `--recv` / `--send` | POST on the connector, FETCH on the listener, one message |
| 2 | `<name>-send-recv` | `send-recv` | `--recv-reply` / `--send-recv` | both directions, each with its own container |
| 3 | `<name>-client-connect` | `client-connect` | `--server-connect` / `--client-connect` | persistent socket proxy, two-way traffic |
| 4 | `<name>-mixed-client-connect` | `client-connect` | slots `{recv: twoSixIndirectComposition, send: <yours>}` swapped between the nodes | the adapter fills only the direction it is asked for |

Pass criterion: the scenario prints `INTEGRATION TEST PASSED ✓` (the final `=== <id>: PASSED` line mirrors it). A scenario's optional `scenarios/link_events/<id>.yaml` check is separate and flaky; do not write one until the basic exchange passes reliably.

### Scenario files

`test/scenarios/<id>.json` use the orchestrator's schema (`id`, `mode`, `wait_time`, `timeout`, `network`, `nodes[]` with `role`/`id`/`ip`/`slots`, `send_message`, `reply_message`). Copy the stub's four files and rename ids, network names and subnets (each scenario needs its own `/24`; the stub uses 10.30.x.0; pick an unused range, e.g. 10.40.x.0). The `"channel"` slot value is the **composition id** from `manifest.json`, never a plugin name.

### The adapter

`test/adapter.py` is the only plugin-specific piece of the harness. Start from `plugins/transport-stub/test/adapter.py` and keep its structure:

- `kit_dir(role)` → the built kit directory (used with no scenario context, only to read the manifest).
- `generate_node_contribution(request)` →
  - `params`: `"<composition id>.<key>"` for every `requestPluginUserInput` key, plus `"<composition id>.actionFile"` = absolute `/kits/<PluginName>/config/<file>`;
  - `cli_flags["send-address"]` / `["recv-address"]`: JSON link addresses (deterministic, see AGENTS.md);
  - `sidecar_services`: extra compose services, e.g. a mock server;
  - credentials only as `${ENV_VAR}` placeholders; fail fast with a clear message if the variable is unset.
- Honour `request.direction` (`None` = fill both; `"send"`/`"recv"` = fill only that one).

## 4. Service-state cleanup

Real services keep what earlier runs posted; a stale message makes a receive pass for the wrong reason and a stale container makes `createLink` take the "already exists" path. Before re-running a scenario delete only that scenario's containers (deterministic names `<prefix>-<scenario>-<role>-send`). Write a small cleanup script for your service (for S3: delete the objects under the scenario's key prefix, with a `--dry-run` option) and filter by the scenario-specific name, never a bare prefix that could match data that is not a test artifact. The stub's mock service lives and dies with the compose project.

## 5. Where to look when it fails

Logs: `test/logs/<ts>-<scenario>/logs/<node-id>/raceboat_<role>.log` (+ `run_scenario.out`, `docker-compose.yml`). Start with `grep -h "PluginName\|ERROR\|WARNING"`; the plugin's own lines are tagged with its log name.

| Symptom | Cause / fix |
|---|---|
| `unknown channel/composition '<id>'` | plugin not in `plugin_registry.json` (use `run_scenarios.py`) or kit not built (`ls kit/artifacts/…`); `python3 raceboat/test/integration/generate_scenario.py --list-channels listener` shows what resolves |
| Component never reaches STARTED / "missing required parameter" | `--param` prefix is not the **composition id**, or the adapter's key differs from the `requestPluginUserInput` key. Check the log line `Got parameter: '<composition>.<key>'` against `onUserInputReceived … answered=1` |
| `createLink`/`loadLinkAddress` returns error, `LINK_DESTROYED` | role check (`currentRole.linkSide` vs the call), `maxLinks`, malformed address JSON — the plugin logs which |
| Listener logs "fetched 0 new message(s)" forever though the service has data | wrong cursor / address (listener loads the container the **connector** posts to), or a bug in the list/parse code (the template once lost every message to a dangling range-`for`) |
| Connector posts (`posted N bytes`) but listener times out | listener fetches a different container name; compare `--send-address` of one node with `--recv-address` of the other in `docker-compose.yml` |
| `docker wait … timed out` | listener container still running: nothing was received (see above), or `--num-packages` not reached |
| Plugin silently ignored, defaults used | manifest key typo — unknown keys are not reported. Compare with the guide's manifest section; grep the log for `Using default value for` |
| `Failed to find encoding for params. Encoding type: …` | `getActionParams`/`kContentType` MIME type matches no encoding in the composition |
| Works after rebuild only sometimes | tag mismatch between builder, runtime and `--image-tag`; or a stale `kit/` (rebuild) |
| Old messages "received" | service state not cleaned (section 4) |

## 6. Done criteria for a new transport

1. `./build_artifacts_in_docker_image.sh` exits 0 on a clean checkout (`rm -rf build kit`).
2. `./run_unit_tests.sh` passes.
3. `test/run_scenarios.py` reports PASSED for all four scenarios in one invocation.
4. `test/logs/` holds the evidence; no secrets in tracked files.

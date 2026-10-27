# AGENTS.md — RACEGEN

## What is this

RACEGEN generates a new **indirect transport mechanism** for the **raceboat framework**.

- **Indirect**: communication between two copies of itself on separate network nodes, moving data through a **third-party service** (e.g. cloud storage, social media).
- **Transport Component**: implements the raceboat Transport Component API (`ITransportComponent`). The reference models are `plugins/transport-stub` (the template; build and test it first) and the framework-team plugins `plugins/skyhook` (AWS S3: a published, real-service transport) and `plugins/decomposed-exemplars` (whiteboard).

The seed service idea is provided externally; the implementation flows from that idea in the steps below. The full spec is `prompt.md`.

## Document map (read in this order)

| Document | Use it for |
|---|---|
| `AGENTS.md` (this file) | workflow, rules, gotchas |
| `plugins/transport-stub/README.md`, `DEVELOPER_GUIDE.md` | the template and the exact steps to turn it into a new transport |
| `RACEBOAT_PLUGIN_DEVELOPMENT_GUIDE.md` | verified API signatures, canonical code patterns, manifest keys, build system |
| `INTEGRATION_TEST_GUIDE.md` | build → unit test → integration test commands, troubleshooting |
| `raceboat/documentation/ChannelAndLinkProperties.md`, `raceboat/test/integration/TESTING_NEW_PLUGINS.md` | framework-owned references (authoritative if they disagree with anything here) |
| `PHASE1_…`, `PHASE2_…`, `PHASE3_…`, `PHASE4_IMPLEMENTATION_STEPS.md`, `PHASE4_TRANSPORT_COMPONENT_DESIGN.md` | **templates for each phase's deliverable** (what to answer, which manifest/code values it fixes), with AWS S3 / `plugins/skyhook` as the worked example. Write the real documents for your service as `HIGH_LEVEL_DESIGN.md`, `PRECISE_DESIGN.md`, `SERVICE_INTERACTION_DESIGN.md`, `TRANSPORT_DESIGN.md`. |
| `TRANSPORT_SERVICE_RESEARCH_AGENT.md` | specification of a Phase 1 research agent that surveys candidate services |

## Implementation workflow (in order)

Four sequential phases. Each produces a markdown design doc + code.

### 1. High-level Design
- Assess the third-party service for suitability: can it store+share data across users with/without credentials? Can data be addressed to recipients? Can interactions be automated via API?
- Produce a markdown assessment listing addressing methods and content types, sorted/annotated by how innocuous they appear to an adversary.

### 2. Precise Design
- Expand the top-rated high-level design into a precise channel definition covering:
  1. Authentication credentials needed for senders/receivers
  2. Data visibility (public vs credential-gated)
  3. Suitable content types and their associated storage/retrieval actions
  4. Bidirectional support (single channel vs two unidirectional instances)
  5. Multicast vs unicast
  6. Data retention duration
  7. Safe post-retrieval deletion

### 3. Service Interaction Implementation
- Implement the service calls behind the `ServiceClient` interface (`plugins/transport-stub/source/transport/ServiceClient.h`): create/exists/delete container, post, fetch-after-cursor. Keep it free of raceboat types.
- Unit-test it (and prove with a real round trip of a few bytes). Credentials are out-of-band: prompt the developer or reuse tokens from earlier stub tests; never hardcode.
- Content encoding is out of scope here.

### 4. Raceboat Transport Component Implementation
- Generate the plugin from the template, never from an empty directory or by copying by hand (see "Where the new plugin goes" below), then follow `plugins/transport-stub/DEVELOPER_GUIDE.md`.
- Key functionalities (all present in the template):
  1. Parameter ingestion via `sdk->requestPluginUserInput` (answers arrive in `onUserInputReceived`)
  2. Encoded content queued via `enqueueContent`, sent by `doAction`
  3. Multiple-link management with proper address creation/loading
  4. User Model action generation for scheduling (the component only declares actions)
- Produce: design document (functionality, security, nuances) + Component Integration document (User Model interaction types + Encoding content types/parameters; template in the stub's `DEVELOPER_GUIDE.md`).
- Build, run the unit tests, then run the four integration scenarios; fix errors until all pass. **A transport is not done until `test/run_scenarios.py` reports every scenario PASSED.**

## Where the new plugin goes and what it is called

```bash
cd /home/ubuntu/racegen
plugins/transport-stub/new_transport.py --name <Name> --out /home/ubuntu/racegen/<name>-transport
```

- **Location:** `/home/ubuntu/racegen/<name>-transport/`, a sibling of `raceboat/` and `plugins/` (`<name>` = `<Name>` with a lower-case first letter). `plugins/` is reserved for the framework-team plugins that are already published. Keep the plugin directly under the racegen directory (or `plugins/`): the adapter and `run_scenarios.py` locate `raceboat/` by searching parent directories, and the plugin is registered in `raceboat/test/integration/plugin_registry.json` by a relative path (done by `run_scenarios.py`).
- **`--name`:** CamelCase, letters and digits only, taken from the service (`S3`, `Mastodon`, `Redis`). It must not collide with an existing composition id (check `python3 raceboat/test/integration/generate_scenario.py --list-channels listener`).
- **Derived names** (all consistent by construction; do not rename by hand): kit directory / manifest `file_path` / CMake `PLUGIN_NAME` `Plugin<Name>`, library `libPlugin<Name>.so`, transport id `<name>`, composition id and channel gid `<name>Composition`, client class `<Name>Client`, environment variables `<NAME>_SERVER` / `<NAME>_TOKEN`, scenario ids `<name>-send-only`, `-send-recv`, `-client-connect`, `-mixed-client-connect`.
- **Collisions to avoid:** pick Docker subnets for the scenarios that no other scenario uses (`raceboat/test/integration/scenarios/*.json`; the template uses 10.30.x.0), and keep service-side container names scenario-specific.
- The generator does not create a git repository. Version the plugin on its own (`git init` inside it, as `plugins/transport-stub` is) and do not add it to the racegen root repo; there it shows up as an untracked directory.

## Build & test (the one canonical sequence)

Run from the plugin directory. `TAG` is the image tag you built raceboat's images with (e.g. `dev`); the builder and runtime images must carry the **same** tag, and every command below takes it as `--image-tag TAG` (or set `RACEBOAT_IMAGE_TAG=TAG` once; the flag overrides it).

```bash
./build_artifacts_in_docker_image.sh --image-tag TAG   # plugin -> kit/artifacts/linux-<arch>-{client,server}/<PluginName>/
./run_unit_tests.sh --image-tag TAG                    # gtest: built in the builder image, run in the runtime image
set -a; . /home/ubuntu/racegen/.env; set +a            # service credentials, if the service needs any
./test/run_scenarios.py --image-tag TAG                # registers plugin, installs scenarios, runs all, saves logs
```

Details, flags and troubleshooting: `INTEGRATION_TEST_GUIDE.md`. If you change raceboat itself, rebuild its images first (`raceboat/test/integration/BUILD_TEST_GUIDE.md`).

## User Model & Actions Files

- Prefer the **file-based user model** (`twoSixFileBasedUserModel`, from `plugins/decomposed-exemplars`) for integration tests; it schedules transport actions from JSON action files.
- Each transport ships action files under `config/` (copied into the kit by CMake):
  - `actions-send-only.json`: POST-only schedule for send-only senders.
  - `actions.json`: FETCH-only schedule for receivers.
  - `actions-combined.json`: POST + FETCH schedule for bidirectional modes.
- The adapter sets `<composition id>.actionFile` to the **absolute** path `/kits/<PluginName>/config/<file>`. (A relative path is resolved against the *user model's* plugin directory, not yours.)
- Action files schedule `post`/`fetch`/`cleanup`; content encoding is handled externally and consumed via `enqueueContent`.
- Do not hardcode action schedules in code; keep them in JSON action files.

## Key gotchas (each one cost a debugging session)

- **`--param` keys are `<composition id>.<key>`**, where `<composition id>` is `compositions[].id` in `manifest.json` and `<key>` is the first argument of `requestPluginUserInput`. The plugin/library name is *not* a valid prefix: such a param is silently never delivered. Do not work around this with `getenv()`.
- **Credentials** are out-of-band: adapters pass `${ENV_VAR}` placeholders (docker compose substitutes them at `up` time). Never write a secret into a file, manifest, log or doc.
- **Manifest keys are exact**: `bandwidth_bps` / `latency_ms` / `loss` (not `bandwidth`), `supportedHints` (not `supported_hints`), `shared_library_path` = the real `lib<Target>.so` name. Unknown keys are silently ignored, so a typo is never reported. See the guide's manifest section.
- **API signatures** are in `raceboat/include/race/decomposed/*.h`; `sdk->requestPluginUserInput(...)` returns a `ChannelResponse` (use `.handle`), not a `RaceHandle`. Do not write mocks by hand; use `raceboat/test/common/MockTransportSdk.h` (copied into `test/source/common/` in the template).
- **Always tell the SDK when a link will not exist**: on every failure path of `createLink`/`loadLinkAddress`/`createLinkFromAddress` call `sdk->onLinkStatusChanged(handle, id, LINK_DESTROYED, {})` — except when the *id already exists* (that would destroy the live link).
- **Wildcard `"linkId": "*"`** in an action applies to every link. `getActionParams` must return a parameter for `fetch` too (`encodePackage=false`) and for `post` (`encodePackage=true`); `cleanup` returns none.
- **`doAction` must return quickly.** Do network I/O on a per-link worker thread (the template's `Link`).
- **Creators post, loaders fetch.** A creator-side link that fetches would hand the node its own messages back and end a send/receive exchange early.
- **Content encoding** is handled outside the transport component — the component consumes already-encoded data via `enqueueContent`.
- The component must support **multiple simultaneous links** with independent address management.
- **Do not use `FetchContent`/network downloads in CMake**; nlohmann_json, gtest/gmock, curl and the race SDK are already in the builder image under `/linux/<arch>`.
- **Unit tests cannot run inside the builder image** (its `libraceSdkCommon.so` needs a newer glibc than the image has); `run_unit_tests.sh` builds there and runs in the runtime image.
- Range-`for` over a member of a temporary (`for (x : json::parse(s).at("k"))`) dangles — it silently produced "no messages" in the first template run. Keep the parsed object in a local.

## Phase 2 Design Principles (Lessons Learned)

### Content Types & Carriers
- **List available content types with sizes/formats only** — do NOT ascribe what data goes in each carrier
- The encoding component (external; e.g. a steganography or media encoder) decides how the payload is distributed across items
- Transport component is carrier-agnostic; it uploads/downloads whatever bytes/files the encoding component produces

### Multicast vs Unicast
- **Identify the channel's inherent type** based on service properties — do not design variants
- Public repos = multicast channel by construction
- If unicast semantics needed, achieve at higher layer (encryption), not in transport design

### Data Retention
- **Describe the service's inherent retention properties**, not configurable policies
- Classify: packet-level (auto-expire), cache-level (LRU), persist-until-deleted (public), permanently-undeletable (email/blockchain), forkable/copiable
- Note deletion capabilities, CDN caching, mirroring/forking, legal retention
- Configurable TTLs are a User Model concern, not a service property

### Bidirectional Support
- Default to **two independent unidirectional channels** unless service natively supports bidirectional
- Each direction: independent credentials, lifecycle, keys, addressing
- Avoid single-channel bidirectional designs (complexity, security, audit issues)

## Integration Testing (Lessons Learned)

### Directionality
- Decide the channel's `linkDirection` in phase 2 and put it in the manifest. The reference transports are **LD_CREATOR_TO_LOADER**: the sender creates the service-side container, the receiver loads its address. Always distinguish creator (owns the container, posts) from loader (fetches).
- Each node owns one container it posts into and loads its peer's. Names are deterministic (`<prefix>-<scenario>-<role>-send`) so nodes predict each other's addresses without exchanging anything.
- Links created from an address whose container already exists (e.g. a reply link) must **reuse** it and mark themselves non-owning so `destroyLink` does not delete a container still in use.

### adapter.py
- Must support the four scenarios: `send` (send-only), `send-recv`, `client-connect`, `mixed-client-connect` (a `{"recv": ..., "send": ...}` slot; the adapter then fills only the direction it is asked for — `request.direction`).
- Select action files by mode/role:
  - send-only connector: `actions-send-only.json` (POST only)
  - send-only listener: `actions.json` (FETCH only)
  - other modes: `actions-combined.json` (POST + FETCH)
- Start from `plugins/transport-stub/test/adapter.py`; it already implements all of the above and is the tested reference.

### Cleanup of Service State
- Real services persist data between runs; stale content causes false receives. Delete the scenario's containers before re-running (e.g. for S3: delete the objects under the scenario's key prefix; always filter by the scenario-specific name, never by a bare prefix that could match other people's data).
- `destroyLink` must delete owned containers; reused links must not.
- `test/run_scenarios.py` preserves every run's output and logs under `test/logs/<timestamp>-<scenario>/` (pass or fail).

### Rebuild & Run Process
1. Edit plugin (or raceboat) code.
2. `./build_artifacts_in_docker_image.sh` (rebuild images first if raceboat itself changed).
3. `./run_unit_tests.sh`.
4. `test/run_scenarios.py --image-tag TAG`; it stops on the first failure.
5. Diagnose from `test/logs/...`, fix, rebuild, rerun from step 2.


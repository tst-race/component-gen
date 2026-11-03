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
| `plugins/encoding-stub/README.md` | the encoding plugin template, Base64 reference, tests, and `new_encoding.py` generator |
| `RACEBOAT_PLUGIN_DEVELOPMENT_GUIDE.md` | verified API signatures, canonical code patterns, manifest keys, build system |
| `INTEGRATION_TEST_GUIDE.md` | build → unit test → integration test commands, troubleshooting |
| `raceboat/documentation/ChannelAndLinkProperties.md`, `raceboat/test/integration/TESTING_NEW_PLUGINS.md` | framework-owned references (authoritative if they disagree with anything here) |
| `PHASE1_…`, `PHASE2_…`, `PHASE3_…`, `PHASE4_IMPLEMENTATION_STEPS.md`, `PHASE4_TRANSPORT_COMPONENT_DESIGN.md` | **Transport templates** for each phase's deliverable (what to answer, which manifest/code values it fixes), with AWS S3 / `plugins/skyhook` as the worked example. Write the real documents for your service as `HIGH_LEVEL_DESIGN.md`, `PRECISE_DESIGN.md`, `SERVICE_INTERACTION_DESIGN.md`, `TRANSPORT_DESIGN.md`. The first two go in `designs/<name>/` (the plugin does not exist yet); in Phase 3, when the plugin is generated, move them into `<name>-transport/docs/` where all four then live. |
| `TRANSPORT_SERVICE_RESEARCH_AGENT.md` | specification of a Phase 1 research agent that surveys candidate services |
| `PHASE1_ENCODING_HIGH_LEVEL_DESIGN.md`, `PHASE2_ENCODING_PRECISE_DESIGN.md`, `PHASE3_ENCODING_PROOF_OF_CONCEPT.md`, `PHASE4_ENCODING_IMPLEMENTATION_STEPS.md`, `PHASE4_ENCODING_COMPONENT_DESIGN.md` | **Encoding templates** for selecting a format tool, specifying capacity/timing, proving exact byte recovery, and implementing an `IEncodingComponent`. Use `plugins/decomposed-exemplars/source/encoding/PluginCommsTwoSixBase64Encoding.*` as the code reference. |
| `ENCODING_TOOL_RESEARCH_AGENT.md`, `.opencode/agent/encoding-researcher.md`, `.opencode/agent/encoding-implementer.md` | encoding research and implementation agent specifications. |

Generate a new encoding plugin from the template, never by editing the template in place:

```bash
python3 plugins/encoding-stub/new_encoding.py \\
  --name Base64 \\
  --mime-type text/plain \\
  --max-bytes 1000000 \\
  --encoding-time-seconds 0.25 \\
  --out /home/ubuntu/racegen/base64-encoding
```

The MIME type, capacity, and encoding-time arguments must come from the approved design and benchmark, not from these example values. The generated source starts from the Base64 exemplar; replace its codec and MIME metadata for any other format, then update tests and rerun the full build and integration gates.

## Workspace setup (one time)

Start from the root of a clone of this repository. The workspace must contain the raceboat framework checkout and three independent plugin checkouts: the transport template, a published real-service example, and the decomposed user-model example. Create this layout before building or generating a transport:

```text
racegen/
├── raceboat/                         # raceboat framework and integration harness
├── plugins/
│   ├── transport-stub/               # template used to generate new transports
│   ├── encoding-stub/                 # template used to generate new encoding plugins
│   ├── skyhook/                      # published AWS S3 transport example
│   └── decomposed-exemplars/          # file-based user model and other examples
└── <name>-transport/                 # generated transport; sibling of raceboat/
```

From the repository root, clone any missing checkouts into these exact destinations. These are separate Git repositories; do not clone them inside the generated transport or move them under another plugin:

```bash
mkdir -p plugins
git clone https://github.com/tst-race/raceboat.git raceboat
git clone https://github.com/tst-race/transport-stub.git plugins/transport-stub
git clone https://github.com/tst-race/skyhook.git plugins/skyhook
git clone https://github.com/tst-race/decomposed-exemplars.git plugins/decomposed-exemplars
```

`scripts/bootstrap.sh` does all of the above on a new system (it also checks prerequisites, installs opencode and pulls the published `raceboat-plugin-builder` / `raceboat-runtime` images with the `main` tag). It never builds images; the default workflow should need no raceboat changes and no image builds beyond adding dependencies that a new plugin requires to the builder/runtime images.

If a destination already exists, keep that checkout and do not run its `git clone` command again. Use `plugins/transport-stub` as the canonical template, `plugins/skyhook` for an implemented service transport and `plugins/decomposed-exemplars` for User Model/action-file patterns. Keep the framework checkout at `raceboat/`; the adapter and scenario runner expect to find it there or in a parent directory.

## Transport implementation workflow (in order)

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

## Encoding component workflow (in order)

Encoding components are separate from transport plugins. The seed is a **declared content format** (for example, PNG, JPEG, text, MP4, or a model-file format), and the work evaluates ordinary format encoders/decoders or serializers that produce that format. The supported scope is transparent format conversion/serialization with exact byte recovery. Cover-file steganography, concealment, stealth/fingerprint ranking, and evasion of detection are out of scope.

Follow the four encoding templates in order; each phase produces its design or implementation deliverable:

1. **High-level design:** survey candidate libraries/tools that can produce and parse the requested format. Compare format support, input requirements, platform/runtime fit, licensing, maintenance, and testability. Write `designs/<format>/ENCODING_HIGH_LEVEL_DESIGN.md`.
2. **Precise design:** select a tool and specify parameters, format validation, actual payload capacity, dependencies, and benchmark conditions. Establish the exact meaning/units of `EncodingProperties.encodingTime` from the framework consumer before assigning it; do not infer units or timing semantics from the field name. Write `ENCODING_PRECISE_DESIGN.md`.
3. **Proof of concept:** create a runnable, isolated encode/decode round trip and tests for arbitrary bytes, malformed input, empty input, and capacity boundaries. Measure and document timing on the target runtime. Write `ENCODING_PROOF_OF_CONCEPT.md`.
4. **Encoding plugin:** implement `IEncodingComponent`, following the base64 example in `plugins/decomposed-exemplars`. Report the actual MIME type, a defensible `maxBytes` for each parameter set, and the scheduler-compatible encoding-time value. Test first with the existing `twoSixIndirect` transport and the new encoding selected in a dedicated composition; then test compatibility with a chosen content-format transport. Do not claim service-transformation robustness unless it is an ordinary, documented format-compatibility check that preserves exact decoded bytes.

The encoding component is not complete until encode/decode round-trip tests pass, declared capacity is verified at its boundary, timing semantics and measurement conditions are recorded, and the initial `twoSixIndirect` integration passes. The later format-specific transport integration is a separate compatibility gate.

## Where the new plugin goes and what it is called

```bash
cd /home/ubuntu/racegen
python3 plugins/transport-stub/new_transport.py --name <Name> --out /home/ubuntu/racegen/<name>-transport
```

Invoke the generator with `python3` rather than executing the script directly, so setup does not depend on its executable bit. If Python cannot read the script or write the destination, do not change ownership or broaden permissions; ask the workspace owner to run the command or provide the intended access.

- **Location:** `/home/ubuntu/racegen/<name>-transport/`, a sibling of `raceboat/` and `plugins/` (`<name>` = `<Name>` with a lower-case first letter). `plugins/` is reserved for the framework-team plugins that are already published. Keep the plugin directly under the racegen directory (or `plugins/`): the adapter and `run_scenarios.py` locate `raceboat/` by searching parent directories, and the plugin is registered in `raceboat/test/integration/plugin_registry.json` by a relative path (done by `run_scenarios.py`).
- **`--name`:** CamelCase, letters and digits only, taken from the service (`S3`, `Mastodon`, `Redis`). It must not collide with an existing composition id (check `python3 raceboat/test/integration/generate_scenario.py --list-channels listener`).
- **Derived names** (all consistent by construction; do not rename by hand): kit directory / manifest `file_path` / CMake `PLUGIN_NAME` `Plugin<Name>`, library `libPlugin<Name>.so`, transport id `<name>`, composition id and channel gid `<name>Composition`, client class `<Name>Client`, environment variables `<NAME>_SERVER` / `<NAME>_TOKEN`, scenario ids `<name>-send-only`, `-send-recv`, `-client-connect`, `-mixed-client-connect`.
- **Collisions to avoid:** pick Docker subnets for the scenarios that no other scenario uses (`raceboat/test/integration/scenarios/*.json`; the template uses 10.30.x.0), and keep service-side container names scenario-specific.
- The generator does not create a git repository. Version the plugin on its own (`git init` inside it, as `plugins/transport-stub` is) and do not add it to the racegen root repo; there it shows up as an untracked directory.

## Credentials for the service (`.env`)

Whatever credentials the new transport needs (tokens, keys, usernames, endpoints) must be available to the process that runs the real-service test. A developer may keep them in `/home/ubuntu/racegen/.env` (gitignored, one `NAME=value` per line) or use their approved environment/secret injection method. There is no template for `.env`, because the variable names depend on the service.

- **Naming:** use `<NAME>_*` (e.g. `<NAME>_TOKEN`, `<NAME>_SERVER`), matching the generated plugin's environment variables.
- **Discover, don't guess:** state exactly which variables the design needs and ask the developer to make them available. Check only whether the required environment variables are present in the process; do not probe `.env` with file tools, `grep`, `stat`, or other commands.
- **Do not access secrets:** never read, echo, log, or copy `.env` values. Do not change its ownership or permissions. If credentials are not available to the agent process, ask the developer to run the real-service command in their own shell with credentials loaded, or to provide them through the approved environment mechanism. Continue with credential-free unit/mock tests where possible.
- **Inject, don't embed:** code reads parameters passed by the SDK; adapters pass `${ENV_VAR}` placeholders to docker compose. Nothing but the variable name may appear in committed or generated files.

## Build & test (the one canonical sequence)

Run from the plugin directory. `TAG` is the image tag you built raceboat's images with (e.g. `dev`); the builder and runtime images must carry the **same** tag, and every command below takes it as `--image-tag TAG` (or set `RACEBOAT_IMAGE_TAG=TAG` once; the flag overrides it).

```bash
./build_artifacts_in_docker_image.sh --image-tag TAG   # plugin -> kit/artifacts/linux-<arch>-{client,server}/<PluginName>/
./run_unit_tests.sh --image-tag TAG                    # gtest: built in the builder image, run in the runtime image
./test/run_scenarios.py --image-tag TAG                # registers plugin, installs scenarios, runs all, saves logs
```

For real-service scenarios that need credentials, run the final command in a developer-owned shell where the required variables are already available. If the developer uses `.env`, they may load it in that shell before running the scenario command; do not ask the agent to read or change `.env`. If variables are unavailable, report the missing variable names only and defer the real-service run.

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

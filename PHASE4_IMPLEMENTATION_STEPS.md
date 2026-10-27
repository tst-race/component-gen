# Phase 4 — Implementation Steps

Build the raceboat transport component from the Phase 2 design and the Phase 3 `ServiceClient`. Start from the template, not from scratch:

```bash
cd /home/ubuntu/racegen
plugins/transport-stub/new_transport.py --name <Name> --out /home/ubuntu/racegen/<name>-transport
```

Then follow `plugins/transport-stub/DEVELOPER_GUIDE.md` (the detailed, command-level version of these steps). Reference for API signatures and patterns: `RACEBOAT_PLUGIN_DEVELOPMENT_GUIDE.md`. For a real-service example of the same structure, read `plugins/skyhook`.

| Step | Do | Where |
|---|---|---|
| 1. Baseline | Generate, build, run the unit tests unchanged | `run_unit_tests.sh --image-tag <tag>` |
| 2. Service | Implement the Phase 3 client | `source/transport/<Name>Client.*` |
| 3. Parameters | Request the credentials/settings with `sdk->requestPluginUserInput`; start/fail the component when all answers arrive | `Plugin<Name>.cpp` |
| 4. Address | Define the JSON link address and its parser | `LinkAddress.*` |
| 5. Channel | Set `linkDirection`, `transmissionType`, `mtu`, retention, MIME types, composition (reuse the `twoSixFileBasedUserModel` user model and `noop`/`base64` encoding from `plugins/decomposed-exemplars`) | `source/manifest.json`, `getTransportProperties` |
| 6. Links | Check create/load/createFromAddress/destroy semantics, ownership and deletion against the design | `Plugin<Name>.cpp`, `Link.*` |
| 7. Schedules | Tune the three action files (post-only, fetch-only, combined) | `config/*.json` |
| 8. Tests | Extend unit tests; adapt the adapter (credentials, container naming, sidecar); run the four scenarios | `test/` |
| 9. Documents | Write the transport design and Component Integration documents | see `PHASE4_TRANSPORT_COMPONENT_DESIGN.md` |

## Credential classes

| Class | Where it goes | Example |
|---|---|---|
| Host-specific, unshared | `requestPluginUserInput` at component start | S3 access key / secret / session token |
| Link-specific, shared with the peer | the link address | bucket, object ids, region |
| Link-specific, unshared | per-link input or a higher layer (e.g. encryption keys) | — |

## Integration test sequence (stop at the first failure)

| Test | Scenario | Passes when |
|---|---|---|
| send-only | connector posts, listener fetches | one message arrives |
| send-recv | request and reply, one container per direction | both arrive |
| client-connect | persistent socket proxy | two-way traffic |
| mixed-client-connect | reference transport upstream, yours downstream (slot `{"recv":…,"send":…}`) | adapter fills only the requested direction |

Run all with `test/run_scenarios.py --image-tag <tag>` (see `INTEGRATION_TEST_GUIDE.md`); at each failure check configuration (directions, address format, roles), plugin loading (kit contents, absolute action-file path, `--param` keys use the composition id), runtime (service calls, auth, rate limits), and completion (no hangs, expected `onReceive` / `onPackageStatusChanged`).

## Principles

1. Reuse the existing user model and encodings; write no user-model or encoding code unless the design requires a new content type (then specify it and stop).
2. The link address is the contract between nodes — define it before the component logic.
3. Never skip a test stage; fix unit tests before debugging integration tests.
4. Build early; rebuild with the same image tag you test with.
5. Credentials are parameters, never constants.

# Phase 3 — Service Interaction Implementation (deliverable template)

**Deliverable:** `SERVICE_INTERACTION_DESIGN.md` + a working `ServiceClient` implementation + tests, proving that a few bytes of arbitrary data can be stored and retrieved through the service. Content encoding is out of scope. The worked example maps AWS S3 (as used by `plugins/skyhook`) onto the template's interface.

## 1. The boundary: `ServiceClient`

All service access sits behind `plugins/transport-stub/source/transport/ServiceClient.h`, free of raceboat types, so it can be developed, tested and replaced independently:

| Operation | Contract | S3 mapping |
|---|---|---|
| `createContainer(id)` | idempotent | create the bucket, or reserve a key prefix in an existing bucket |
| `containerExists(id)` | no side effects | HeadBucket / list the prefix |
| `deleteContainer(id)` | creator only | DeleteObjects under the prefix (and the bucket if owned) |
| `post(id, bytes)` → message id | throws `ServiceError(kind, …)` | PutObject with a sortable key (zero-padded sequence or time-ordered id); return the key |
| `fetchAfter(id, cursor)` | newer than `cursor`, oldest first; missing container → empty list | ListObjectsV2 `StartAfter=cursor`, then GetObject for each key |

Message ids must compare in post order (the cursor depends on it) or the cursor logic in `Link::fetchOnActionThread` must change. Classify failures: `Transient` (network, 5xx), `NotFound`, `Auth`, `RateLimited` (e.g. S3 503 SlowDown), `Fatal`.

## 2. Document

- the exact calls (endpoint, method, parameters, response fields) for each operation, with the credentials each needs;
- authentication details (what is signed/sent, expiry and refresh);
- limits and the retry/backoff policy;
- the address fields this implies (what a peer needs to find the data) — input to `LinkAddress`;
- what the service sees (request patterns, metadata) — input to the security notes.

## 3. Implement and test

1. Implement `<Name>Client.{h,cpp}` from the template's `StubClient`. Keep the HTTP/SDK code, wrapping and quirks here.
2. Unit-test it against a fake server or recorded responses (parse errors, 404 handling, ordering, pagination).
3. Provide a small proof-of-concept program or test that does create → post → fetchAfter → delete against the **real** service.

## 4. Credentials for this phase

Ask the developer for what the service needs, keep it in `/home/ubuntu/racegen/.env` (gitignored) or the environment, and reuse it for the Phase 4 integration test. Never put it in code, manifests, scenario files, docs or logs. In Phase 4 the same values reach the component through `requestPluginUserInput` (`--param <composition id>.<key>`).

## 5. Done when

- the proof-of-concept round-trips a few arbitrary bytes through the real service and cleans up after itself;
- the client's unit tests pass;
- the design note lists limits, errors, and the address fields.

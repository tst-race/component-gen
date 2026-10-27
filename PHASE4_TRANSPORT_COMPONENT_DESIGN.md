# Phase 4 — Transport Component Design Document (deliverable template)

**Deliverable:** `TRANSPORT_DESIGN.md` for the new transport (functionality, security, nuances) and a **Component Integration** section that other component authors can implement against. Examples use the S3/Skyhook transport.

## 1. Functionality

- Component diagram: `Plugin<Name>` → `Link` (one container + one worker thread each) → `ServiceClient`.
- Link directions and roles: which side creates, which loads, who posts, who fetches.
- Lifecycle of `createLink`, `createLinkFromAddress`, `loadLinkAddress`, `destroyLink` (what happens on the service, who owns and deletes what).
- How the link address is built and parsed (schema + example). Example (Skyhook):
  `{"region":"eu-west-2","fetchBucket":"b","initialFetchObjUuid":"…","postBucket":"b","initialPostObjUuid":"…","maxTries":5,"openObjects":1,"singleReceive":true}`
- Error handling: service error kinds → package status; retries; what is logged.
- Multiple simultaneous links and their independent state (`maxLinks`).

## 2. Security

- Credentials: which ones, how they reach the component (`--param <composition id>.<key>`), that they are never logged or persisted, minimum scope.
- Note that `race-cli --debug` prints parameter values: raw test logs are secret.
- What the service, another user and a network observer can learn (names, sizes, timing, access patterns).
- Retention and deletion behaviour from the Phase 2 design.

## 3. Nuances

Rate limits, ordering/consistency assumptions, behaviour when the peer is late (loader must tolerate a missing container), cursor persistence across restarts, wildcard (`"*"`) actions, anything surprising.

## 4. Component Integration

### 4.1 User model interaction

| Item | Content |
|---|---|
| Actions | `post`, `fetch`, `cleanup` (state what each does and which content type it needs) |
| `linkId` forms | a concrete link id or `"*"` (every link) |
| Events emitted | `{"linkId":…,"actionId":…,"status":"posted"\|"fetched"\|"failed"}` — when each is sent |
| Hints (`supportedHints`) | which hints the user model may rely on |
| Timing constraints | service rate limits, minimum polling interval, schedule files shipped in `config/` |

### 4.2 Encoding interaction

| Item | Content |
|---|---|
| MIME types | those in `getTransportProperties` (e.g. `application/octet-stream`) |
| Size limits | `mtu` and service limits |
| Encoding parameters | contents of `EncodingParameters::json`, if any |
| Suitable encodings | which of `noop`, `base64`, or a media/steganography encoding fit; note that with several matching encodings the framework silently picks the first |

### 4.3 Parameters

| `--param` key (`<composition id>.<key>`) | Meaning | Secret | Required | Example |
|---|---|---|---|---|

### 4.4 Addresses

The `LinkAddress` JSON schema with an example and which fields the adapter fills for each scenario mode.

## 5. Test evidence

The commands run and the result of each of the four scenarios (`test/run_scenarios.py`), and the location of the preserved logs.

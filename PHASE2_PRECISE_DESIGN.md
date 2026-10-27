# Phase 2 — Precise Design (deliverable template)

**Deliverable:** `PRECISE_DESIGN.md`. Expand the top-rated Phase 1 option into a precise channel definition. Answer every section; the answers directly fix manifest values and code (noted in *italics*). The worked example is AWS S3 as used by `plugins/skyhook`.

Principles (see also `AGENTS.md`): describe the service's **inherent** properties, not configurable policy; list content types by size/format only; default to two independent unidirectional channels; leave timing to the user model.

## 1. Authentication credentials

For senders and receivers separately: what credential, which scope/permissions, how it is acquired out-of-band, rotation. State what is secret.
*Becomes the `requestPluginUserInput` keys and the adapter's `${ENV_VAR}` placeholders.*

> S3: writer (AccountHolder) needs access key, secret key and optionally a session token, plus the account's canonical id and region; reader (PublicUser) needs none. Skyhook asks for `canonicalId`, `region`, `bucket`, `seed`, `singleReceive` via user input.

## 2. Data visibility

Who can read what was uploaded: everyone, or only specific credentials? Can that be chosen per link?
*Decides `transmissionType` and whether the receiver needs credentials.*

> S3: public-read objects are readable by anyone with the key (multicast by construction); private objects need credentials.

## 3. Content types and actions

Table of content types the service can hold (format, size limits) paired with the **action** that stores and retrieves each. The transport is content-agnostic: it moves whatever bytes the encoding produces.
*Becomes `getTransportProperties()` (action → MIME types) and `kContentType`.*

| Content | MIME | Store action | Retrieve action | Limits |
|---|---|---|---|---|
| Opaque object | `application/octet-stream` | `post` (PutObject) | `fetch` (List/GetObject) | 5 GB per PUT |

## 4. Bidirectional support

Default: **two independent unidirectional channels** (one container per direction, each with its own credentials, lifecycle and address). Single-channel bidirectional only if the service natively supports it; justify.
*Becomes `linkDirection` (`LD_CREATOR_TO_LOADER`, `LD_LOADER_TO_CREATOR` or `LD_BIDI`) and the creator/loader roles.*

## 5. Multicast or unicast

State the channel's **inherent** type from section 2. Unicast semantics, if needed, come from encryption at a higher layer.
*Becomes `transmissionType`.*

## 6. Data retention

Classify the service's inherent retention: auto-expiring packets, cache/LRU, persist-until-deleted, permanently undeletable, forkable/copiable. Note CDN caching, mirroring, legal retention and what deletion really does. Timing policies are a user-model concern.
*Becomes `duration_s` / `period_s` (or -1) and the deletion design.*

> S3: persists until deleted or a lifecycle rule expires it; versioning (if enabled) keeps deleted versions.

## 7. Safe post-retrieval deletion

Can data be deleted after retrieval without creating suspicious service usage? Who deletes (creator only), when, and how to avoid deleting something still in use.
*Becomes `destroyLink` and the cleanup action.*

## 8. Address format and link lifecycle

The JSON address two nodes exchange (fields, which are mandatory, an example, nothing secret) and the lifecycle (created → posting → fetched → destroyed).
*Becomes `LinkAddress`.*

> Skyhook: `{"region","fetchBucket","initialFetchObjUuid","postBucket","initialPostObjUuid","maxTries","openObjects","singleReceive"}`.

## 9. Limits, errors, security

- Rate/size limits and the backoff strategy (map service errors to `Transient`, `NotFound`, `Auth`, `RateLimited`, `Fatal`).
- What an observer, another user and the service can learn; credential handling (never logged, never in files).
- Parameters (per composition) with secret/required/default.

## 10. Output summary

A short table of the manifest values this design fixes: `linkDirection`, `transmissionType`, `sendType`, `reliable`, `mtu`, `duration_s`, `period_s`, `maxLinks`, `supportedHints`, MIME types, parameters.

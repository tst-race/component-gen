# Phase 1 — High-Level Design (deliverable template)

**Deliverable:** `HIGH_LEVEL_DESIGN.md` for the seed service. Assess whether the service can carry an indirect transport and rank the ways of using it by how innocuous they look to an adversary. The worked example below is AWS S3, the service behind the published `plugins/skyhook` transport; replace it with the service being assessed.

## 1. Suitability assessment (answer each, with evidence)

| Question | Why it matters | S3 example (Skyhook) |
|---|---|---|
| Can data be stored such that someone with the same, different, **or no** credentials can read it? | decides sender/receiver credentials and whether a receiver needs an account | objects in a public-read bucket are readable by an unauthenticated GET; writing needs AWS credentials. Skyhook ships two builds for this: AccountHolder (writes) and PublicUser (reads only) |
| Can data be **addressed** to a recipient so they find it efficiently? | defines the link address and polling cost | bucket + object key; a receiver polls one known key/prefix, so no scanning |
| Can every operation be automated through an API? Which tokens are needed? | decides the service client and the parameters to request | S3 REST/SDK; access key, secret key and (temporary) session token for the writer |
| Rate limits, size limits, quotas, cost | bounds throughput, `mtu` and polling interval | per-prefix request-rate limits (HTTP 503 SlowDown), 5 GB per PUT, paid account |
| Is read-after-write consistent? Can items be listed in order? | determines the fetch cursor design | strongly consistent; keys list in lexicographic order |
| What does the service log or expose to others (access logs, public listing, search)? | feeds the adversary assessment | bucket policy and access logs are visible to the account owner/AWS |

## 2. Addressing methods

List every way a receiver can be pointed at the data. For each: precise definition, how a receiver finds it, discovery/polling overhead, and an **innocuousness rating** against three adversaries — another user, a network observer, the service itself.

| Method | Definition | Overhead | User | Network | Service |
|---|---|---|---|---|---|
| Known object key in a shared bucket | address carries `{bucket, key}` | 1 GET per poll | medium | high (TLS to a cloud provider) | low (stored in the account) |
| Key prefix with sequence numbers | address carries `{bucket, prefix}`; receiver lists after the last key it saw | 1 LIST + GETs | medium | high | low |
| *(add the service's other methods)* | | | | | |

## 3. Content types

List each kind of content the service can hold with **size limits and formats only** (do not decide what payload goes where; the encoding component does that). Rate each for innocuousness the same way.

| Content type | MIME / format | Size limit | Notes |
|---|---|---|---|
| Opaque object | `application/octet-stream` | 5 GB per PUT | trivially detectable as non-natural content |
| Text / JSON object | `text/plain`, `application/json` | per policy | needs an encoding such as base64 |
| Image / media object | `image/png`, `image/jpeg`, … | per policy | needs a media/steganography encoding component |

## 4. Ranking and recommendation

Sort the (addressing method × content type) combinations by overall innocuousness and by practicality. Recommend one for Phase 2 and say why the others lose. State the open risks (rate limits, account cost, mandatory logging).

## 5. Next-phase inputs

The Phase 2 questions this assessment leaves open (credential scope, retention, deletion side effects).

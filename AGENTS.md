# AGENTS.md — RACEGEN

## What is this

RACEGEN generates a new **indirect transport mechanism** for the **raceboat framework**.

- **Indirect**: communication between two copies of itself on separate network nodes, moving data through a **third-party service** (e.g. cloud storage, social media).
- **Transport Component**: implements the raceboat Transport Component API. Existing implementations (redis, mastodon, AWS S3) are the reference models.

The seed service idea is provided externally; the implementation flows from that idea in the steps below.

## Implementation workflow (in order)

The project is built in 4 sequential phases. Each produces a markdown design doc + code.

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
- Build stub code + unit tests for the service API interactions.
- Iterate on credentials/tokens until the stubs can store/retrieve a small amount of arbitrary data (proof of concept). Content encoding is out of scope here.

### 4. Raceboat Transport Component Implementation
- Implement the raceboat-compliant transport component using the precise design + service stubs.
- Key functionalities:
  1. Parameter ingestion via `requestUserInput` APIs
  2. Encoded content queued via `EnqueueData`
  3. Multiple-link management with proper address creation/loading
  4. User Model action generation for scheduling (component only declares actions)
- Produce: design document (functionality, security, nuances) + Component Integration document (User Model interaction types + Encoding content types/parameters).
- Compile and run integration tests; fix errors until passing.

## Reference materials

- Model implementations: redis, mastodon, AWS S3 transport components (find in the raceboat framework repo).
- The full detailed spec lives in `prompt.md`.

## Key gotchas

- **Third-party service credentials** are out-of-band — prompt the developer or reuse tokens from prior stub tests. Do not hardcode.
- **Content encoding** is handled outside the transport component — the component consumes already-encoded data via `EnqueueData`.
- The component must support **multiple simultaneous links** with independent address management.

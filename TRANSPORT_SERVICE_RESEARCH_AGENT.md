# Transport Service Research Agent Specification

## Purpose

An autonomous agent that searches, evaluates, and ranks third-party services suitable for use as **indirect transport mechanisms** in the Raceboat framework. This agent executes **Phase 1 (High-Level Design)** of the RACEGEN workflow.

---

## Core Responsibilities

1. **Discover** candidate third-party services with APIs that can store/share data
2. **Evaluate** each service against transport suitability criteria
3. **Rank** candidates by "innocuousness" (adversarial stealth)
4. **Produce** a structured High-Level Design markdown document

---

## Input Parameters

```json
{
  "seed_ideas": ["optional: list of service names or categories to prioritize"],
  "exclusions": ["optional: services to exclude (e.g., already used: AWS S3, Mastodon, Redis)"],
  "requirements": {
    "must_support_unauthenticated_read": true,
    "must_have_programmatic_api": true,
    "max_monthly_cost_usd": 0,
    "geographic_restrictions": []
  },
  "output_path": "/path/to/HIGH_LEVEL_DESIGN.md",
  "permissions": {
    "require_approval_per_request": true,
    "approved_domains": [],
    "max_requests_per_run": 50,
    "request_timeout_seconds": 30
  }
}
```

---

## Search Strategy

### 1. Service Categories to Investigate

| Category | Examples | Key Question |
|----------|----------|--------------|
| **Cloud Storage** | Backblaze B2, Wasabi, Cloudflare R2, Google Cloud Storage, Azure Blob, MinIO (self-hosted), Storj, Filebase | Can create pre-signed URLs for unauthenticated access? |
| **Code Hosting** | GitHub Gists, GitLab Snippets, Bitbucket Snippets, Sourcehut pastes | Can create/update via API without auth? Rate limits? |
| **Paste/Note Services** | Pastebin, Ghostbin, PrivateBin, Hastebin, 0x0.st, dpaste, ix.io, termbin.com | API for create/retrieve? Expiration policies? |
| **Message Boards/Forums** | Reddit (subreddits), Discourse instances, PHPbb, custom forums | Post/edit via API? Public read? |
| **Social Media** | Twitter/X, Mastodon (other instances), Bluesky/AT Protocol, Nostr, Threads | Character limits? Media upload? Public read? |
| **Document/Note APIs** | Notion, Google Docs, Etherpad, HackMD, CodiMD, Obsidian Sync | API access? Public sharing? |
| **DNS/TXT Records** | Cloudflare, AWS Route53, Google Cloud DNS, Namecheap, GoDaddy | TXT record size limits? API for updates? |
| **Blockchain/Decentralized** | IPFS (pinning services), Arweave, Filecoin, Storj, Sia, BTFS | Cost? Persistence? Gateway access? |
| **Email/Services** | Temporary email APIs, Mailgun, SendGrid, Postmark | Can receive via API? Public inbox? |
| **Key-Value Stores** | Redis Cloud, Upstash, Vercel KV, Cloudflare Workers KV, Deno KV | Public read endpoints? |
| **CDN/Edge Storage** | Cloudflare R2, Cloudflare Workers KV, Netlify Blobs, Vercel Blob | Edge access? Public URLs? |
| **IoT/Telemetry** | ThingsBoard, Ubidots, Adafruit IO, Datacake | Public dashboards? API write? |
| **Collaboration Tools** | Google Sheets/Forms, Airtable, Notion DB, Coda, Baserow | API append/read? Public view? |

### 2. Search Queries (Automated)

```python
SEARCH_QUERIES = [
    # Direct API searches
    "free cloud storage API anonymous public read",
    "pastebin API create read without account",
    "github gist API anonymous create",
    "reddit API post read public subreddit",
    "mastodon API public timeline no auth",
    "nostr relay public write read",
    "ipfs pinning service free api",
    "cloudflare workers kv public read api",
    "temporary email api receive messages",
    "google sheets api append public read",
    "airtable api public view",
    "cloudflare r2 presigned url public",
    "backblaze b2 public bucket api",
    "wasabi s3 compatible public read",
    
    # Comparative searches
    "best free file hosting api 2024",
    "anonymous file sharing service api",
    "censorship resistant communication channel api",
    "dead drop service api digital",
]
```

### 3. Discovery Sources

| Source | Method | Requires Permission |
|--------|--------|---------------------|
| **GitHub** | Search repos: `topic:file-sharing api`, `topic:pastebin clone`, `stars:>100` | Yes (api.github.com) |
| **ProgrammableWeb** | API directory category: File Sharing, Storage | Yes (www.programmableweb.com) |
| **RapidAPI / APILayer** | Browse Storage, File Sharing categories | Yes (rapidapi.com, apilayer.com) |
| **Awesome Lists** | `awesome-selfhosted`, `awesome-privacy`, `awesome-decentralized` | Yes (raw.githubusercontent.com) |
| **Reddit/HN** | Search: "free file hosting API", "anonymous paste API" | Yes (www.reddit.com, hn.algolia.com) |
| **Documentation Sites** | Direct vendor docs for API capabilities | Yes (per vendor domain) |

---

## Permission System (TEMPORARY RESTRICTION)

### Overview

For the first several runs, **every external HTTP request requires explicit human approval**. This ensures visibility into what domains are being accessed and what data is being requested.

### Permission Flow

```
1. Agent identifies need for external request
   ↓
2. Agent constructs RequestIntent object:
   {
     "id": "req_abc123",
     "phase": "discovery|evaluation|testing",
     "method": "GET|POST",
     "url": "https://api.github.com/search/repositories?q=...",
     "domain": "api.github.com",
     "purpose": "Search for pastebin-like repositories with API",
     "headers": {"Accept": "application/vnd.github.v3+json"},
     "body": null,
     "estimated_cost": "0 API credits"
   }
   ↓
3. Agent PAUSES and presents RequestIntent to human
   ↓
4. Human reviews and responds:
   - APPROVE: Request executes immediately
   - APPROVE_DOMAIN: All future requests to this domain auto-approved this run
   - DENY: Request skipped, agent adapts
   - DENY_DOMAIN: Domain blocked for this run
   - ABORT: Stop entire run
   ↓
5. If approved, request executes, response cached
   ↓
6. Agent continues
```

### RequestIntent Schema

```json
{
  "id": "string (unique per request)",
  "phase": "discovery|evaluation|testing",
  "method": "GET|POST|HEAD",
  "url": "string (full URL)",
  "domain": "string (extracted domain)",
  "purpose": "string (human-readable reason)",
  "headers": "object (request headers, secrets redacted)",
  "body": "string|null (request body if POST, truncated to 500 chars)",
  "estimated_cost": "string (API credits, rate limit impact, monetary cost)",
  "cache_key": "string (for deduplication)"
}
```

### Approval Response Schema

```json
{
  "request_id": "req_abc123",
  "decision": "APPROVE|APPROVE_DOMAIN|DENY|DENY_DOMAIN|ABORT",
  "reason": "optional human note",
  "modifications": {
    "headers": "optional header overrides",
    "params": "optional query param overrides",
    "timeout_seconds": "optional override"
  }
}
```

### Permission State Persistence

- **Per-run cache**: Approved domains cached for duration of single agent execution
- **Session log**: All requests + decisions logged to `permission_log_<timestamp>.jsonl`
- **No cross-run persistence**: Each run starts fresh (temporary restriction)

### CLI Interaction Example

```
┌─────────────────────────────────────────────────────────────────┐
│ PERMISSION REQUEST #3 (discovery phase)                         │
├─────────────────────────────────────────────────────────────────┤
│ Domain:      api.github.com                                     │
│ Method:      GET                                                │
│ URL:         https://api.github.com/search/repositories?        │
│              q=topic%3Afile-sharing+api+stars%3A%3E100          │
│ Purpose:     Find pastebin-like services with public APIs       │
│ Headers:     Accept: application/vnd.github.v3+json             │
│ Est. Cost:   1/30 core search API credits (rate limited)       │
├─────────────────────────────────────────────────────────────────┤
│ [A]pprove  [D]omain-approve  [S]kip  [B]lock-domain  [Q]uit    │
└─────────────────────────────────────────────────────────────────┤
Decision: 
```

### Batch Approval Mode (Future)

After initial runs demonstrate safe behavior, a `batch_approval` mode can be enabled where:
- Pre-approved domain list loaded from config
- Only new/unknown domains prompt
- Full audit log still maintained

---

## PermissionGate Interface Specification

### Class Definition

```python
class PermissionGate:
    """
    Mediates all external HTTP requests. Blocks until human approval received.
    
    Usage:
        gate = PermissionGate(mode="interactive", approved_domains=[])
        
        # In agent code, before ANY external request:
        intent = RequestIntent(...)
        response = gate.request_approval(intent)
        
        if response.decision == Decision.APPROVE:
            http_client.request(...)
```

### Constructor

```python
def __init__(
    self,
    mode: Literal["interactive", "batch", "auto_approve_domains"] = "interactive",
    approved_domains: List[str] = None,  # Domains pre-approved for this run
    max_requests: int = 50,               # Hard limit per run
    log_path: str = "permission_log.jsonl",  # Audit log output
    timeout_seconds: int = 300,           # Max wait for human response
    cli_prompt: Callable = default_cli_prompt  # Override for testing
):
```

### RequestIntent Dataclass

```python
@dataclass
class RequestIntent:
    id: str                    # UUID4
    phase: Literal["discovery", "evaluation", "testing"]
    method: Literal["GET", "POST", "HEAD", "PUT", "DELETE"]
    url: str
    domain: str                # Auto-extracted from URL
    purpose: str
    headers: Dict[str, str]    # Secrets auto-redacted in display
    body: Optional[str]        # Truncated to 500 chars for display
    estimated_cost: str
    cache_key: str             # For deduplication
    timestamp: float           # Unix epoch
```

### Decision Enum

```python
class Decision(Enum):
    APPROVE = "approve"              # Execute this request once
    APPROVE_DOMAIN = "approve_domain"  # Execute + cache domain approval
    DENY = "deny"                    # Skip this request
    DENY_DOMAIN = "deny_domain"      # Skip + block domain for this run
    ABORT = "abort"                  # Stop entire agent run
```

### ApprovalResponse Dataclass

```python
@dataclass
class ApprovalResponse:
    request_id: str
    decision: Decision
    reason: Optional[str] = None
    modifications: Optional[Dict] = None  # Header/param overrides
```

### Core Method

```python
def request_approval(self, intent: RequestIntent) -> ApprovalResponse:
    """
    Blocks until human provides decision.
    
    Flow:
    1. Check cache: if domain approved → return APPROVE_DOMAIN response
    2. Check blocklist: if domain denied → return DENY_DOMAIN response
    3. Check max_requests: if exceeded → return ABORT response
    4. Render intent to CLI/TUI
    5. Wait for human input (with timeout)
    6. Log to JSONL: {intent, response, timestamp}
    7. Update cache/blocklist based on decision
    8. Return response
    """
```

### Cache Behavior

```python
# Internal state (not persisted across runs)
self._approved_domains: Set[str] = set()      # From APPROVE_DOMAIN
self._denied_domains: Set[str] = set()        # From DENY_DOMAIN
self._request_count: int = 0
self._request_log: List[Dict] = []            # For JSONL output
```

### JSONL Log Format

```json
{"timestamp": 1705342100.123, "event": "request", "intent": {...}}
{"timestamp": 1705342105.456, "event": "response", "response": {...}, "duration_ms": 5333}
{"timestamp": 1705342200.789, "event": "request", "intent": {...}}
{"timestamp": 1705342201.012, "event": "response", "response": {"decision": "APPROVE_DOMAIN", ...}, "duration_ms": 223}
```

### Default CLI Prompt (Reference Implementation)

```python
def default_cli_prompt(intent: RequestIntent) -> ApprovalResponse:
    print(f"\n{'='*60}")
    print(f"PERMISSION REQUEST #{gate._request_count + 1} ({intent.phase})")
    print(f"{'='*60}")
    print(f"Domain:      {intent.domain}")
    print(f"Method:      {intent.method}")
    print(f"URL:         {intent.url}")
    print(f"Purpose:     {intent.purpose}")
    print(f"Headers:     {json.dumps(redact_secrets(intent.headers), indent=2)}")
    if intent.body:
        print(f"Body:        {intent.body[:500]}")
    print(f"Est. Cost:   {intent.estimated_cost}")
    print(f"{'='*60}")
    print("[A]pprove  [D]omain-approve  [S]kip  [B]lock-domain  [Q]uit")
    
    while True:
        choice = input("Decision: ").strip().lower()
        if choice in ('a', 'approve'):
            return ApprovalResponse(intent.id, Decision.APPROVE)
        elif choice in ('d', 'domain'):
            return ApprovalResponse(intent.id, Decision.APPROVE_DOMAIN)
        elif choice in ('s', 'skip'):
            return ApprovalResponse(intent.id, Decision.DENY)
        elif choice in ('b', 'block'):
            return ApprovalResponse(intent.id, Decision.DENY_DOMAIN)
        elif choice in ('q', 'quit'):
            return ApprovalResponse(intent.id, Decision.ABORT)
        print("Invalid choice. Use A/D/S/B/Q")
```

### Testing Mode

```python
# For unit tests - auto-approves everything
test_gate = PermissionGate(mode="auto_approve_domains")

# For batch mode with pre-approved list
batch_gate = PermissionGate(
    mode="batch",
    approved_domains=["api.github.com", "raw.githubusercontent.com"]
)
```

---

## Evaluation Framework

### Mandatory Criteria (Pass/Fail)

| Criterion | Test Method | Pass Condition |
|-----------|-------------|----------------|
| **Programmatic API** | Documentation review | REST/GraphQL/gRPC API exists |
| **Store Capability** | API test / docs | Can write data via API |
| **Retrieve Capability** | API test / docs | Can read data via API |
| **Addressing** | API test / docs | Can target specific recipient (key, ID, tag, hashtag, path) |
| **Cross-User Access** | API test / docs | Data written by User A readable by User B (same/diff creds/no creds) |

### Scoring Criteria (0-10 each)

| Dimension | Weight | Description |
|-----------|--------|-------------|
| **Innocuousness** | 30% | How normal/suspicious does traffic look? (1=obvious covert channel, 10=indistinguishable from normal use) |
| **Authentication Flexibility** | 20% | Supports: no auth, API key, OAuth, pre-signed URLs, anonymous |
| **Data Size Limits** | 15% | Max object size, daily/monthly quotas |
| **Retention Control** | 10% | Can delete after retrieval? Auto-expiration? |
| **Bidirectional Support** | 10% | Single channel bidirectional or need two unidirectional? |
| **Multicast Efficiency** | 5% | One write → many readers efficiently? |
| **Rate Limits / Cost** | 5% | Free tier generous? Pay-as-you-go reasonable? |
| **Geographic Availability** | 5% | Global access? Regional restrictions? |

### Innocuousness Scoring Guide

| Score | Profile | Examples |
|-------|---------|----------|
| **10** | Ubiquitous, high-volume, expected encryption | DNS-over-HTTPS, TLS certificates, CDN assets |
| **9** | Common dev tools, public by design | GitHub Gists, Pastebin, npm packages |
| **8** | Popular consumer services | Twitter posts, Reddit comments, Imgur images |
| **7** | Niche but legitimate | Mastodon toots, Nostr notes, IPFS gateways |
| **6** | Developer-focused storage | Cloudflare KV, GitHub releases, GitLab packages |
| **5** | Specialized but public | Temporary email, paste bins with API |
| **4** | Unusual but explainable | DNS TXT records, blockchain memos |
| **3** | Suspicious patterns | Single-purpose obscure APIs |
| **2** | Clearly covert-channel-like | "Anonymous dead drop" services |
| **1** | Known malicious infrastructure | Tor hidden services only, burner domains |

---

## Agent Workflow

### Phase 1: Broad Discovery (Parallel)

```
For each category in SERVICE_CATEGORIES:
  1. For each search query:
     a. Construct RequestIntent
     b. PAUSE → PermissionGate.request_approval(intent)
     c. If approved: execute search, cache results
     d. If denied: skip, log reason
  2. Collect 5-10 candidate services per category
  3. For each candidate homepage/docs:
     a. Construct RequestIntent
     b. PAUSE → PermissionGate.request_approval(intent)
     c. If approved: fetch and parse
  4. Store raw data in candidate database
```

### Phase 2: Mandatory Filtering

```
For each candidate:
  1. Check: Has programmatic API?
  2. Check: Can store data?
  3. Check: Can retrieve data?
  4. Check: Addressing mechanism exists?
  5. Check: Cross-user access possible?
  6. FAIL → move to "rejected" with reason
```

### Phase 3: Deep Evaluation (Parallel)

```
For each passing candidate:
  1. Analyze API docs (permission-gated fetches):
     - Auth methods (none, key, OAuth, signed URLs)
     - Object size limits
     - Rate limits (req/min, req/day, bandwidth)
     - Retention policies (TTL, manual delete)
     - Public vs private access controls
     - Geographic endpoints
     - Cost structure
  2. Test minimal API interaction (if free tier / no auth):
     For each test operation (create/read/delete):
       a. Construct RequestIntent with test payload
       b. PAUSE → PermissionGate.request_approval(intent)
       c. If approved: execute, record latency/result
       d. If denied: mark dimension as "untested", use docs only
  3. Score on all 8 dimensions
  4. Document addressing methods & content types
```

### Phase 4: Ranking & Output

```
1. Sort by weighted score (descending)
2. Group by category
3. Annotate top 3 with detailed pros/cons
4. Generate HIGH_LEVEL_DESIGN.md
```

---

## Output Format: HIGH_LEVEL_DESIGN.md

```markdown
# High-Level Design: [Service Name] Transport Assessment

## Executive Summary
- **Recommended**: Yes/No
- **Overall Score**: X.Y/10
- **Category**: Cloud Storage / Social Media / etc.
- **Best For**: Unicast / Multicast / Bidirectional

## Service Overview
- **Name**: 
- **Website**: 
- **API Docs**: 
- **Pricing Page**: 
- **Free Tier**: 

## Mandatory Criteria Assessment
| Criterion | Pass/Fail | Evidence |
|-----------|-----------|----------|
| Programmatic API | ✅ | REST API v3 documented at ... |
| Store Capability | ✅ | POST /objects endpoint |
| Retrieve Capability | ✅ | GET /objects/{id} |
| Addressing | ✅ | Object key + bucket, or hashtag-like tags |
| Cross-User Access | ✅ | Public buckets / pre-signed URLs / shared keys |

## Detailed Scoring

| Dimension | Score | Weight | Weighted | Notes |
|-----------|-------|--------|----------|-------|
| Innocuousness | 8 | 30% | 2.4 | Traffic looks like normal CI/CD artifact uploads |
| Auth Flexibility | 9 | 20% | 1.8 | Supports anonymous public read, API keys, presigned URLs |
| Data Size Limits | 7 | 15% | 1.05 | 5GB/object, 1000 req/day free |
| Retention Control | 8 | 10% | 0.8 | Manual delete, lifecycle policies |
| Bidirectional | 6 | 10% | 0.6 | Two buckets needed for clean separation |
| Multicast | 5 | 5% | 0.25 | One object, many readers via public URL |
| Rate Limits/Cost | 8 | 5% | 0.4 | Generous free tier, $0.005/GB after |
| Geographic | 9 | 5% | 0.45 | Global CDN, multiple regions |
| **TOTAL** | | **100%** | **7.85** | |

## Addressing Methods (Ranked by Innocuousness)

| Method | Description | Innocuousness | Implementation Complexity |
|--------|-------------|---------------|---------------------------|
| **Pre-signed GET URLs** | Sender creates object, generates time-limited public read URL, shares URL via side channel | 9/10 | Low |
| **Public Bucket + Predictable Keys** | Both parties know bucket + key pattern (e.g., `msg/{uuid}`), sender writes, receiver polls | 7/10 | Medium |
| **Tag/Metadata Filtering** | Objects tagged with recipient ID, receiver lists + filters | 6/10 | Medium |
| **Webhook/Notification** | Service pushes notification on new object | 5/10 | High (requires receiver endpoint) |

## Content Types & Actions

| Content Type | Max Size | Store Action | Retrieve Action | Encoding Notes |
|--------------|----------|--------------|-----------------|----------------|
| Raw Binary | 5 GB | `PUT /objects/{key}` | `GET /objects/{key}` | Any encoding works |
| Base64 String | 5 GB | `PUT /objects/{key}` | `GET /objects/{key}` | Base64 encoding component |
| JSON Metadata + Binary | 5 GB | `PUT /objects/{key}?meta=...` | `GET /objects/{key}` | Metadata for addressing |

## Authentication Requirements

| Role | Credentials Needed | How Obtained |
|------|-------------------|--------------|
| **Sender** | API Key (write), or Presigned URL (write) | Account creation → API key gen |
| **Receiver** | None (public read), or API Key (private read) | Pre-signed URL from sender, or shared key |

## Data Visibility
- ✅ Public buckets: Anyone with URL/key can read
- ✅ Private buckets: API key required for read
- ✅ Presigned URLs: Time-limited, no credentials needed

## Retention & Deletion
- **Default Retention**: Infinite (until deleted)
- **Manual Delete**: DELETE /objects/{key} — immediate
- **Lifecycle Policies**: Auto-delete after N days
- **Suspicion Risk**: Low — object deletion is normal operational behavior

## Bidirectional Strategy
- **Approach**: Two independent unidirectional channels (separate buckets/keyspaces)
- **Rationale**: Cleaner separation, avoids key collision, each direction independently configurable

## Multicast Support
- **Native**: No (one writer per object)
- **Workaround**: Single object, multiple readers via public URL — efficient for small groups

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Service adds rate limiting | Medium | High | Implement exponential backoff, multiple accounts |
| Service blocks anonymous read | Low | High | Fallback to authenticated read with shared key |
| Object storage used for malware distribution | Medium | Medium | Content scanning, encryption at rest |
| Geographic blocking | Low | Medium | Multi-region deployment |

## Recommendation
**PROCEED TO PHASE 2** — This service scores 7.85/10 and meets all mandatory criteria. The pre-signed URL approach provides high innocuousness with low implementation complexity.

---

## Alternative Candidates (Summary Table)

| Service | Score | Category | Key Strength | Key Weakness |
|---------|-------|----------|--------------|--------------|
| Cloudflare R2 | 8.2 | Cloud Storage | Zero egress fees, S3-compatible | Requires account |
| GitHub Gists | 7.5 | Code Hosting | No auth for public, high trust | 10MB limit, rate limited |
| Nostr Relays | 7.2 | Decentralized | Censorship resistant, no auth | Ephemeral, relay-dependent |
| Cloudflare Workers KV | 7.0 | Edge KV | Global, free tier | 25MB/value, 1K writes/day |
| Pastebin.com | 6.8 | Paste Service | Simple API, public by default | 10 min expiration default, ads |
| DNS TXT Records | 6.5 | DNS | Universal, cached globally | 255 char/record, slow propagation |
| IPFS (Pinata) | 6.0 | Decentralized | Content-addressed, permanent | Gateway latency, pinning costs |
| ... | ... | ... | ... | ... |
```

---

## Integration with RACEGEN

### Invocation Point

```bash
# After AGENTS.md is read, before Phase 1 begins
python -m transport_research_agent \
  --exclusions "AWS S3,Mastodon,Redis" \
  --output HIGH_LEVEL_DESIGN.md
```

### Handoff to Phase 2

The agent outputs:
1. `HIGH_LEVEL_DESIGN.md` — Primary deliverable
2. `candidates.json` — Machine-readable ranked list for Phase 2 agent
3. `api_samples/` — Working request/response examples for top 3

### Phase 2 Agent Consumes

```json
{
  "selected_service": "Cloudflare R2",
  "addressing_method": "presigned_urls",
  "content_types": ["raw_binary", "base64"],
  "auth_scheme": "api_key_sender_only",
  "bidirectional_strategy": "two_unidirectional"
}
```

---

## Implementation Checklist for Agent Developer

### Core Capabilities

- [ ] **Permission gate: RequestIntent → human approval → execute** (REQUIRED)
- [ ] **Permission CLI/TUI for human review** (REQUIRED)
- [ ] **Permission log writer (JSONL)** (REQUIRED)
- [ ] Web search integration (SerpAPI, Brave Search API, or browser automation)
- [ ] HTTP client for API testing (with retry, timeout, auth)
- [ ] Markdown/JSON output generation
- [ ] Structured logging for audit trail
- [ ] Configurable scoring weights

### Data Sources

- [ ] GitHub API (repo search, topics)
- [ ] ProgrammableWeb / RapidAPI directories
- [ ] Direct vendor documentation scraping
- [ ] Awesome-list parsing (GitHub raw URLs)

### Evaluation Engine

- [ ] Mandatory criteria checker (rule-based)
- [ ] Scoring rubric with weighted dimensions
- [ ] Innocuousness heuristic (traffic pattern analysis)
- [ ] API test harness (create/read/delete cycle)

### Safety & Ethics

- [ ] **Permission system: Every external request requires explicit approval** (temporary)
- [ ] Respect robots.txt and ToS
- [ ] Rate limit all external requests (max 1 req/sec per domain default)
- [ ] No credential storage (prompt at runtime)
- [ ] Only test free tiers / public endpoints
- [ ] Clean up test artifacts after evaluation
- [ ] Redact secrets from logs (API keys, tokens in headers/body)
- [ ] Request/response bodies truncated in logs (max 500 chars)
- [ ] Permission log written to disk for audit

---

## Example Agent Invocation

```python
# transport_research_agent/__main__.py
from transport_research_agent import ResearchAgent, PermissionGate

# Permission gate (REQUIRED for initial runs)
permission_gate = PermissionGate(
    mode="interactive",  # "interactive" | "batch" | "auto_approve_domains"
    approved_domains=[],  # Pre-approved domains (empty initially)
    max_requests=50,
    log_path="permission_log_20240115.jsonl"
)

agent = ResearchAgent(
    exclusions=["AWS S3", "Mastodon", "Redis"],
    requirements={
        "must_support_unauthenticated_read": True,
        "max_monthly_cost_usd": 5.00,
    },
    scoring_weights={
        "innocuousness": 0.30,
        "auth_flexibility": 0.20,
        # ... etc
    },
    permission_gate=permission_gate  # INJECTED DEPENDENCY
)

results = agent.run()
agent.write_report("HIGH_LEVEL_DESIGN.md")
agent.write_candidates_json("candidates.json")
```

---

## Future Enhancements

1. **Automated Phase 2 Transition** — Generate precise design skeleton from top candidate
2. **Service Monitoring** — Periodic re-evaluation for API changes, pricing, ToS updates
3. **Adversarial Simulation** — Network traffic analysis to validate innocuousness scores
4. **Multi-Region Testing** — Latency/availability from different geographies
5. **Compliance Checking** — GDPR, data residency, encryption at rest verification

---

## Related Documents

- `RACEBOAT_PLUGIN_DEVELOPMENT_GUIDE.md` — Implementation guide for the transport component
- `AGENTS.md` — Overall RACEGEN workflow (Phases 1-4)
- `prompt.md` — Detailed Phase 1 requirements
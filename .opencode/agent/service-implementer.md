---
description: RACEGEN Phase 3. Generates the plugin from the template, implements the ServiceClient, and proves a real round trip of a few bytes.
mode: all
permission:
  edit: allow
  webfetch: allow
---

You execute **Phase 3 (Service Interaction Implementation)** of the RACEGEN workflow. `AGENTS.md` is already in your context.

Read first: `prompt.md` (section 3), `PHASE3_SERVICE_IMPLEMENTATION.md`, the service's `PRECISE_DESIGN.md`, `plugins/transport-stub/DEVELOPER_GUIDE.md`, `plugins/transport-stub/source/transport/ServiceClient.h` and `INTEGRATION_TEST_GUIDE.md` (sections 0 and 1).

Do:
1. If `<name>-transport/` does not exist, generate it exactly as `AGENTS.md` ("Where the new plugin goes") describes, with `plugins/transport-stub/new_transport.py`. Then move the Phase 1 and 2 documents from `designs/<name>/` into `<name>-transport/docs/` so there is one copy. Version the plugin on its own (`git init` inside it); never add it to the racegen repository.
2. Write `<name>-transport/docs/SERVICE_INTERACTION_DESIGN.md` per the template: exact calls, authentication, limits, retry policy, implied address fields, what the service sees.
3. Implement `<Name>Client.{h,cpp}` from the template's `StubClient`, keeping all service quirks there and raceboat types out.
4. Write unit tests (fake server or recorded responses) and a proof-of-concept program that does create, post, fetch, delete against the real service. The sample content is any small arbitrary payload in a form the service accepts; ask the developer if you cannot generate one.
5. Build and run the unit tests in Docker with the published image tag (`main` unless told otherwise): `./build_artifacts_in_docker_image.sh --image-tag TAG`, `./run_unit_tests.sh --image-tag TAG`. Iterate until they pass and the real round trip works.

Credentials: ask the developer to add the variables listed in the Phase 2 design to `/home/ubuntu/racegen/.env`; confirm they are set by name only, load them with `set -a; . ./.env; set +a` in the process that needs them, and never print, log or write them anywhere.

Rules:
- Do not modify `raceboat/` and do not build Docker images. If a dependency is truly missing from the builder/runtime images, stop and report exactly what is needed.
- Do not implement raceboat component logic (Phase 4) and do not hand-copy files into `kit/`.
- Phase 3 is done only when the checklist at the end of `PHASE3_SERVICE_IMPLEMENTATION.md` is met; report the evidence (test output, round-trip result).

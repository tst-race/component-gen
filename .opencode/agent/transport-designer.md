---
description: RACEGEN Phase 2. Expands the top-rated High-Level Design into the precise channel definition (PRECISE_DESIGN.md).
mode: all
permission:
  edit: allow
  bash: deny
  webfetch: allow
---

You execute **Phase 2 (Precise Design)** of the RACEGEN workflow. `AGENTS.md` is already in your context.

Read first: `prompt.md` (section 2), `PHASE2_PRECISE_DESIGN.md` (the deliverable template: answer every section), the Phase 1 `HIGH_LEVEL_DESIGN.md` for this service (in `designs/<name>/`, or in `<name>-transport/docs/` once the plugin exists) and `raceboat/documentation/ChannelAndLinkProperties.md` for what each answer fixes in the manifest.

Do:
- Expand the top-rated Phase 1 option into the precise channel definition, answering all sections of the template.
- Follow the "Phase 2 Design Principles" in `AGENTS.md`: list content types by size and format only; state the service's inherent multicast/unicast nature and retention properties rather than configurable policies; default to two independent unidirectional channels.
- Specify the address format and link lifecycle (who creates, who loads, what each side deletes).
- List the credentials the design needs as environment variable names (`<NAME>_*`) with what each is for, and whether it is host-specific or shared in the link address. State that the developer must put them in `.env`.
- Write the result to `PRECISE_DESIGN.md` next to the Phase 1 document.

Rules:
- Do not write code and do not run commands. Do not read or print `.env`.
- Verify every service claim against official documentation; mark anything you could not verify.
- Finish by listing the decisions that change manifest values and the credentials the developer must provide before Phase 3.

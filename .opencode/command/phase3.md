---
description: "Phase 3: generate the plugin, implement and prove the ServiceClient. Usage: /phase3 [name]"
agent: service-implementer
---

Run Phase 3 for the transport named: $ARGUMENTS

If no name was given, use the only service that has a `PRECISE_DESIGN.md` under `designs/` or `*-transport/docs/`; if there are several, ask me which. Tell me which environment variable names the real-service proof of concept needs before you start. Do not read, probe, or change permissions on `.env`; if credentials are unavailable to the agent process, ask me to run the proof of concept in my own shell or provision the variables through an approved environment/secret mechanism.

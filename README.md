# RACEGEN

RACEGEN generates new **indirect transport components** for the [raceboat](https://github.com/tst-race/raceboat) framework: given a seed idea for a third-party service (cloud storage, social media, ...), an AI agent works through four phases to produce a design, a tested service client, and a raceboat transport plugin that passes the integration scenarios. The workflow spec is [prompt.md](prompt.md); the rules the agents follow are in [AGENTS.md](AGENTS.md).

## Quick start (opencode)

Requirements: `git`, `docker` (daemon running, your user allowed to use it), `python3`, `curl`.

```bash
git clone https://github.com/tst-race/component-gen.git racegen
cd racegen
scripts/bootstrap.sh        # installs opencode if missing, clones raceboat + reference plugins, pulls images
opencode auth login         # choose an LLM provider (credentials stay outside the repo)
opencode                    # start in the repository root
```

`scripts/bootstrap.sh` is safe to re-run. It clones `raceboat` and `plugins/{transport-stub,decomposed-exemplars,skyhook}` from `main` (plain clones, no submodules; existing checkouts are left alone) and pulls the published `raceboat-plugin-builder` and `raceboat-runtime` images (`main` tag, override with `RACEBOAT_IMAGE_TAG`; skip with `--no-pull`). It does not build images: the workflow is meant to need no raceboat changes and no image builds, other than adding dependencies that a new plugin needs to the builder/runtime images.

## Workflow

Run the phases in order inside opencode. Each phase is a command backed by a custom agent in [.opencode/agent/](.opencode/agent) and ends with a deliverable for you to review before the next phase.

| Command | Agent | Result |
|---|---|---|
| `/phase1 <seed service idea>` | `service-researcher` | `designs/<name>/HIGH_LEVEL_DESIGN.md`: suitability assessment, addressing methods and content types ranked by innocuousness |
| `/phase2 [name]` | `transport-designer` | `PRECISE_DESIGN.md`: credentials, visibility, content types and actions, directionality, multicast, retention, deletion, address format |
| `/phase3 [name]` | `service-implementer` | `<name>-transport/` generated from `plugins/transport-stub`, a tested `ServiceClient`, `SERVICE_INTERACTION_DESIGN.md`, proof of a real round trip |
| `/phase4 [name]` | `transport-implementer` | the transport component, action files, adapter and scenarios, `TRANSPORT_DESIGN.md` with the Component Integration section; all four integration scenarios passing |
| `/integ-test <name> [scenario ...]` | `transport-implementer` | rebuild and rerun scenarios, diagnosing failures |

The generated transport lives in `<name>-transport/`, next to `raceboat/` and `plugins/`. It is its own project (`git init` inside it) and is ignored by this repository.

## Credentials for the target service

If the service needs credentials, put them in `.env` at the repository root (gitignored), one `NAME=value` per line. The names depend on the service; the Phase 2 agent lists the ones it needs (`<NAME>_TOKEN`, ...) and asks you to add them. The agents never read or print `.env`: it is loaded only into the environment of the build and test commands (`set -a; . ./.env; set +a`) and reaches the plugin as parameters. Never commit it.

## Layout

| Path | Purpose |
|---|---|
| `AGENTS.md`, `prompt.md` | rules and spec (read by any agent that supports `AGENTS.md`) |
| `PHASE*.md`, `INTEGRATION_TEST_GUIDE.md`, `RACEBOAT_PLUGIN_DEVELOPMENT_GUIDE.md`, `TRANSPORT_SERVICE_RESEARCH_AGENT.md` | deliverable templates and guides |
| `opencode.json` | opencode project configuration (permissions, instructions) |
| `.opencode/agent/`, `.opencode/command/` | the phase agents and commands |
| `scripts/bootstrap.sh` | new-system setup |
| `raceboat/`, `plugins/` | cloned by the bootstrap script (not committed) |
| `designs/<name>/` | Phase 1-2 documents, moved into `<name>-transport/docs/` in Phase 3 |
| `<name>-transport/` | generated transports (not committed) |

## Using another tool

Only `opencode.json` and `.opencode/` are opencode-specific. The substance is in `AGENTS.md`, `prompt.md` and the `PHASE*.md` files, so any agent that reads `AGENTS.md` and can run shell commands can follow the same phases: point it at those files and give it the prompt from the matching agent file.

#!/usr/bin/env bash
# Prepare a new system for the RACEGEN workflow. Safe to re-run: existing
# clones and images are left untouched.
#
#   scripts/bootstrap.sh [--no-pull]
#
#   --no-pull   do not pull the published raceboat Docker images
#
# Environment:
#   RACEBOAT_IMAGE_TAG   tag of the published raceboat images to pull (default: main)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${RACEBOAT_IMAGE_TAG:-main}"
IMAGE_NS="ghcr.io/tst-race/raceboat"
PULL=1
[[ "${1:-}" == "--no-pull" ]] && PULL=0

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# --- 1. Prerequisites -------------------------------------------------------
missing=()
for tool in git docker python3 curl; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
[[ ${#missing[@]} -eq 0 ]] || die "missing required tools: ${missing[*]} (install them and re-run)"
docker info >/dev/null 2>&1 || die "cannot talk to the Docker daemon (is it running, and is your user in the docker group?)"

# --- 2. opencode ------------------------------------------------------------
export PATH="$HOME/.opencode/bin:$PATH"
if command -v opencode >/dev/null 2>&1; then
    log "opencode present: $(opencode --version 2>/dev/null || echo unknown version)"
else
    log "installing opencode"
    curl -fsSL https://opencode.ai/install | bash
    command -v opencode >/dev/null 2>&1 || warn "opencode installed but not on PATH; add \$HOME/.opencode/bin to PATH"
fi

# --- 3. Framework and reference plugins (cloned from main, no submodules) ---
clone() {  # clone <repo-url> <dest>
    local url="$1" dest="$2"
    if [[ -d "$dest/.git" ]]; then
        local branch dirty
        branch="$(git -C "$dest" branch --show-current)"
        dirty="$(git -C "$dest" status --porcelain | wc -l)"
        log "$(basename "$dest") already cloned (branch: ${branch:-detached}, $dirty modified/untracked)"
        [[ "$branch" == "main" ]] || warn "$dest is not on main; leaving it as is"
    elif [[ -e "$dest" ]]; then
        die "$dest exists but is not a git clone"
    else
        log "cloning $url -> ${dest#"$ROOT"/}"
        git clone --branch main "$url" "$dest"
    fi
}

mkdir -p "$ROOT/plugins"
clone https://github.com/tst-race/raceboat.git "$ROOT/raceboat"
# transport-stub is the template for new transports, decomposed-exemplars supplies
# the user model and encodings, skyhook is a real-service reference transport.
for p in transport-stub decomposed-exemplars skyhook; do
    clone "https://github.com/tst-race/$p.git" "$ROOT/plugins/$p"
done

# --- 4. Published raceboat images (pulled, never built here) ----------------
if [[ $PULL -eq 1 ]]; then
    for img in raceboat-plugin-builder raceboat-runtime; do
        ref="$IMAGE_NS/$img:$TAG"
        if docker image inspect "$ref" >/dev/null 2>&1; then
            log "image present: $ref"
        else
            log "pulling $ref"
            docker pull "$ref" || warn "could not pull $ref"
        fi
    done
fi

cat <<EOF

Bootstrap complete. Next steps:
  1. Configure an LLM provider:   opencode auth login
  2. If the target service needs credentials, put them in $ROOT/.env (gitignored).
     The agents will tell you which variable names they need.
  3. Start the workflow:          cd $ROOT && opencode
     then run /phase1 <seed service idea>
EOF

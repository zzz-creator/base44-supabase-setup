#!/bin/sh
set -eu

usage() {
    cat <<'EOF'
Usage: sh scripts/commit-submodule.sh <submodule-path> <commit-message> [--yes]

Commit all current changes in one configured submodule, then commit only its
updated pointer in the root repository. This script does not push either repo.
Use --yes to skip the staged-file confirmation after reviewing the printed list.
EOF
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    usage >&2
    exit 2
fi

SUBMODULE=$1
MESSAGE=$2
ASSUME_YES=0
if [ "$#" -eq 3 ]; then
    [ "$3" = "--yes" ] || { usage >&2; exit 2; }
    ASSUME_YES=1
fi
[ -n "$MESSAGE" ] || { echo "Error: commit message cannot be empty." >&2; exit 2; }

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
git -C "$ROOT" rev-parse --show-toplevel >/dev/null 2>&1 || {
    echo "Error: root Git repository not found at $ROOT." >&2
    exit 1
}

SUBMODULE_PATHS=$(awk '
    /^\[submodule / { in_submodule = 1; next }
    /^\[/ { in_submodule = 0 }
    in_submodule && /^[[:space:]]*path[[:space:]]*=/ {
        sub(/^[^=]*=/, "")
        sub(/^[[:space:]]*/, "")
        sub(/[[:space:]]*$/, "")
        print
    }
' "$ROOT/.gitmodules")
if ! printf '%s\n' "$SUBMODULE_PATHS" | grep -Fqx "$SUBMODULE"; then
    echo "Error: '$SUBMODULE' is not a configured submodule." >&2
    printf 'Configured submodules:\n%s\n' "$SUBMODULE_PATHS" >&2
    exit 2
fi

SUBMODULE_DIR="$ROOT/$SUBMODULE"
[ -d "$SUBMODULE_DIR" ] || {
    echo "Error: submodule is not initialized: $SUBMODULE" >&2
    echo "Run: git submodule update --init --recursive" >&2
    exit 1
}
git -C "$SUBMODULE_DIR" rev-parse --show-toplevel >/dev/null 2>&1 || {
    echo "Error: '$SUBMODULE' is not a Git repository." >&2
    exit 1
}

if ! git -C "$ROOT" diff --cached --quiet; then
    echo "Error: root index has staged changes. Commit or unstage them before using this helper." >&2
    exit 1
fi
if ! git -C "$SUBMODULE_DIR" diff --cached --quiet; then
    echo "Error: '$SUBMODULE' already has staged changes. Unstage them before using this helper." >&2
    exit 1
fi

# Fail early if either repository lacks the identity required for its commit.
git -C "$SUBMODULE_DIR" var GIT_AUTHOR_IDENT >/dev/null
git -C "$ROOT" var GIT_AUTHOR_IDENT >/dev/null

git -C "$SUBMODULE_DIR" add --all
if ! git -C "$SUBMODULE_DIR" diff --cached --quiet; then
    STAGED_PATHS=$(git -C "$SUBMODULE_DIR" diff --cached --name-only)
    UNSAFE_PATHS=
    OLD_IFS=$IFS
    IFS='
'
    for path in $STAGED_PATHS; do
        case "$path" in
            .env|.env.*)
                case "$path" in
                    .env.example|.env.*.example|.env.template) ;;
                    *) UNSAFE_PATHS="${UNSAFE_PATHS}${UNSAFE_PATHS:+
}$path" ;;
                esac
                ;;
            */.env|*/.env.*)
                case "$path" in
                    */.env.example|*/.env.*.example|*/.env.template) ;;
                    *) UNSAFE_PATHS="${UNSAFE_PATHS}${UNSAFE_PATHS:+
}$path" ;;
                esac
                ;;
            *client_secret*.json|*.pem|*.p12|*.pfx|*.key|*.log|*/node_modules/*|node_modules/*|*/dist/*|dist/*|*/coverage/*|coverage/*|*/.cache/*|.cache/*|*/.vite/*|.vite/*)
                UNSAFE_PATHS="${UNSAFE_PATHS}${UNSAFE_PATHS:+
}$path"
                ;;
        esac
    done
    IFS=$OLD_IFS

    if [ -n "$UNSAFE_PATHS" ]; then
        echo "Error: refusing to commit likely secrets or generated files:" >&2
        printf '%s\n' "$UNSAFE_PATHS" >&2
        git -C "$SUBMODULE_DIR" reset --quiet
        echo "These paths remain in the worktree but have been unstaged. Update the relevant .gitignore or inspect them, then retry." >&2
        exit 1
    fi

    echo "Submodule changes to commit in '$SUBMODULE':"
    printf '%s\n' "$STAGED_PATHS"
    if [ "$ASSUME_YES" -ne 1 ]; then
        if [ ! -t 0 ]; then
            echo "Error: non-interactive use requires --yes after reviewing the staged paths." >&2
            exit 1
        fi
        printf "Commit these paths? [y/N] "
        IFS= read -r answer || answer=
        case "$answer" in
            y|Y|yes|YES) ;;
            *)
                git -C "$SUBMODULE_DIR" reset --quiet
                echo "Canceled; paths remain in the worktree but have been unstaged." >&2
                exit 1
                ;;
        esac
    fi

    git -C "$SUBMODULE_DIR" commit -m "$MESSAGE" \
        -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
else
    echo "No uncommitted changes in '$SUBMODULE'; checking whether its root pointer needs updating."
fi

git -C "$ROOT" add -- "$SUBMODULE"
if git -C "$ROOT" diff --cached --quiet; then
    echo "Root submodule pointer is already current; nothing to commit in the root."
    exit 0
fi

git -C "$ROOT" commit -m "chore: update $SUBMODULE submodule" \
    -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

echo "Committed '$SUBMODULE' and its root pointer. Push each repository separately when ready."

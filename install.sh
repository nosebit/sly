#!/usr/bin/env bash
#
# Sly installer — https://github.com/nosebit/sly
#
# Installs (or upgrades) Sly in a project: copies the framework into `.sly/`
# and exposes its commands to the IDEs/agents you use.
#
#   curl -fsSL https://raw.githubusercontent.com/nosebit/sly/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/nosebit/sly/main/install.sh | bash -s -- --ide antigravity,claude
#
# Run with --help for all options.
#
# NOTE: keep this script compatible with bash 3.2 (the macOS default): no
# associative arrays, no `mapfile`, no `${var,,}`.

set -euo pipefail

SLY_REPO="${SLY_REPO:-nosebit/sly}"
SUPPORTED_IDES="antigravity claude copilot cursor gemini"

# Files and folders inside `.sly/` owned by the installer. Everything else
# there (notably `memory/`) belongs to the project and is never touched.
MANAGED_CORE="README.md rules.md commands templates .gitignore"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Sly installer

Usage:
  install.sh [options]

Options:
  --ide <list>       Comma-separated IDEs/agents to integrate with, or "all".
                     Supported: ${SUPPORTED_IDES// /, }.
                     Defaults to the ones from the previous install, or asks.
  --version <tag>    Sly release to install (e.g. v0.1.0). Defaults to the
                     latest release. Also read from \$SLY_VERSION.
  --dir <path>       Project to install into. Defaults to the current folder.
  --source <path>    Install from a local checkout of the sly repo instead of
                     downloading a release (useful for development).
  --uninstall        Remove Sly from the project (keeps .sly/memory/).
  -h, --help         Show this help.
EOF
}

info() { printf '%s\n' "$*"; }
warn() { printf 'sly: warning: %s\n' "$*" >&2; }
die() {
  printf 'sly: error: %s\n' "$*" >&2
  exit 1
}

ide_label() {
  case "$1" in
    antigravity) echo "Antigravity" ;;
    claude) echo "Claude Code" ;;
    copilot) echo "VS Code (GitHub Copilot)" ;;
    cursor) echo "Cursor" ;;
    gemini) echo "Gemini CLI" ;;
    *) echo "$1" ;;
  esac
}

is_supported_ide() {
  case " $SUPPORTED_IDES " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# Normalizes a comma/space separated IDE list into a space separated one,
# validating every entry.
parse_ide_list() {
  local raw="$1" out="" ide
  if [ "$raw" = "all" ]; then
    echo "$SUPPORTED_IDES"
    return
  fi
  for ide in ${raw//,/ }; do
    is_supported_ide "$ide" || die "unsupported IDE '$ide' (supported: ${SUPPORTED_IDES// /, })"
    case " $out " in *" $ide "*) ;; *) out="${out:+$out }$ide" ;; esac
  done
  [ -n "$out" ] || die "no IDE given"
  echo "$out"
}

# Escapes a string for use inside a double quoted YAML/TOML string.
quote() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '"%s"' "$s"
}

# Reads the `description:` field from a command file's frontmatter.
command_description() {
  awk '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && sub(/^description:[ \t]*/, "") { print; exit }
  ' "$1"
}

# ---------------------------------------------------------------------------
# IDE adapters
#
# Each adapter is a thin wrapper which tells the agent to read and follow the
# real command in `.sly/commands/`. To support a new IDE, add it to
# SUPPORTED_IDES, ide_label, adapter_path and adapter_content.
# ---------------------------------------------------------------------------

adapter_path() {
  case "$1" in
    antigravity) echo ".agents/skills/sly.$2/SKILL.md" ;;
    claude) echo ".claude/commands/sly.$2.md" ;;
    copilot) echo ".github/prompts/sly.$2.prompt.md" ;;
    cursor) echo ".cursor/commands/sly.$2.md" ;;
    gemini) echo ".gemini/commands/sly.$2.toml" ;;
  esac
}

adapter_content() {
  local ide="$1" name="$2" desc="$3"
  local instr="Read \`.sly/commands/$name.md\` from the project root and execute its instructions."

  case "$ide" in
    antigravity)
      printf -- '---\nname: sly.%s\ndescription: %s\n---\n\n%s\n' "$name" "$(quote "$desc")" "$instr"
      ;;
    claude)
      printf -- '---\ndescription: %s\n---\n\n%s\n\nUser input: $ARGUMENTS\n' "$(quote "$desc")" "$instr"
      ;;
    copilot)
      printf -- '---\ndescription: %s\n---\n\n%s\n' "$(quote "$desc")" "$instr"
      ;;
    cursor)
      printf '%s\n' "$instr"
      ;;
    gemini)
      printf 'description = %s\nprompt = """\n%s\n\nUser input: {{args}}\n"""\n' "$(quote "$desc")" "$instr"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Manifest (`.sly/.manifest`): records what the last install wrote, so
# upgrades can clean up stale files and reuse the chosen IDEs.
# ---------------------------------------------------------------------------

manifest_get() {
  [ -f "$MANIFEST" ] || return 0
  sed -n "s/^$1=//p" "$MANIFEST"
}

# Removes a file and then any parent folders left empty, up to the project.
remove_file() {
  local rel="$1" dir
  rm -f "$TARGET/$rel"
  dir="$(dirname "$rel")"
  while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
    rmdir "$TARGET/$dir" 2>/dev/null || break
    dir="$(dirname "$dir")"
  done
}

remove_previous_adapters() {
  local rel
  for rel in $(manifest_get file); do
    remove_file "$rel"
  done
}

# ---------------------------------------------------------------------------
# Fetching sources
# ---------------------------------------------------------------------------

resolve_latest_version() {
  local url
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$SLY_REPO/releases/latest" 2>/dev/null || true)"
  case "$url" in
    */releases/tag/*) echo "${url##*/}" ;;
    *) echo "main" ;; # no release published yet
  esac
}

# Sets SRC to a folder containing the sly repo and VERSION to its label.
fetch_source() {
  if [ -n "$SOURCE" ]; then
    [ -d "$SOURCE/core/commands" ] || die "'$SOURCE' doesn't look like a sly checkout (missing core/commands)"
    SRC="$(cd "$SOURCE" && pwd)"
    VERSION="local"
    return
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required"
  command -v tar >/dev/null 2>&1 || die "tar is required"

  VERSION="${VERSION:-$(resolve_latest_version)}"
  local ref
  if [ "$VERSION" = "main" ]; then
    ref="heads/main"
  else
    ref="tags/$VERSION"
  fi

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  info "Downloading Sly $VERSION..."
  curl -fsSL "https://github.com/$SLY_REPO/archive/refs/$ref.tar.gz" |
    tar -xzf - -C "$TMP_DIR" --strip-components=1 ||
    die "failed to download Sly $VERSION"
  SRC="$TMP_DIR"
}

# ---------------------------------------------------------------------------
# Interactive IDE selection
# ---------------------------------------------------------------------------

prompt_ides() {
  # When piped through `curl | bash`, stdin is the script itself, so read the
  # answer from the terminal instead.
  if ! (exec </dev/tty) 2>/dev/null; then
    die "no IDE selected; pass --ide <list> (supported: ${SUPPORTED_IDES// /, })"
  fi

  local i=1 ide answer choice selected=""
  {
    echo
    echo "Which IDEs/agents do you want Sly to integrate with?"
    for ide in $SUPPORTED_IDES; do
      echo "  $i) $(ide_label "$ide")"
      i=$((i + 1))
    done
    printf 'Enter numbers separated by commas (e.g. 1,2): '
  } >/dev/tty
  read -r answer </dev/tty

  for choice in ${answer//,/ }; do
    i=1
    for ide in $SUPPORTED_IDES; do
      if [ "$choice" = "$i" ] || [ "$choice" = "$ide" ]; then
        selected="${selected:+$selected,}$ide"
      fi
      i=$((i + 1))
    done
  done
  [ -n "$selected" ] || die "no valid IDE selected"
  echo "$selected"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

do_uninstall() {
  [ -d "$SLY_DIR" ] || die "Sly is not installed in $TARGET"
  remove_previous_adapters
  local item
  for item in $MANAGED_CORE .manifest .tmp; do
    rm -rf "${SLY_DIR:?}/$item"
  done
  rmdir "$SLY_DIR" 2>/dev/null || true
  info "Sly was removed from $TARGET."
  if [ -d "$SLY_DIR" ]; then
    info "Project files in .sly/ (e.g. memory/) were kept."
  fi
}

do_install() {
  local ides
  if [ -n "$IDES" ]; then
    ides="$(parse_ide_list "$IDES")"
  elif [ -n "$(manifest_get ides)" ]; then
    ides="$(parse_ide_list "$(manifest_get ides)")"
  else
    ides="$(parse_ide_list "$(prompt_ides)")"
  fi

  fetch_source

  # 1. Clean up whatever the previous install wrote outside `.sly/`.
  remove_previous_adapters

  # 2. Replace the managed part of `.sly/`, keeping project files.
  mkdir -p "$SLY_DIR/memory"
  local item
  for item in $MANAGED_CORE; do
    rm -rf "${SLY_DIR:?}/$item"
    if [ -e "$SRC/core/$item" ]; then
      cp -R "$SRC/core/$item" "$SLY_DIR/$item"
    fi
  done

  # 3. Write the IDE adapters, recording them in the new manifest.
  local manifest_tmp ide cmd name desc rel
  manifest_tmp="$(mktemp)"
  {
    echo "# Generated by the Sly installer. Do not edit."
    echo "version=$VERSION"
    echo "ides=${ides// /,}"
  } >"$manifest_tmp"

  for ide in $ides; do
    for cmd in "$SLY_DIR"/commands/*.md; do
      name="$(basename "$cmd" .md)"
      desc="$(command_description "$cmd")"
      [ -n "$desc" ] || warn "command '$name' has no description"
      rel="$(adapter_path "$ide" "$name")"
      mkdir -p "$(dirname "$TARGET/$rel")"
      adapter_content "$ide" "$name" "$desc" >"$TARGET/$rel"
      echo "file=$rel" >>"$manifest_tmp"
    done
  done
  mv "$manifest_tmp" "$MANIFEST"

  # 4. Report.
  info ""
  info "Sly $VERSION installed in $TARGET"
  for ide in $ides; do
    info "  - $(ide_label "$ide")"
  done
  info ""
  if [ -s "$SLY_DIR/memory/lore.md" ]; then
    info "Your project lore was kept. Run /sly.goal to spec your next feature."
  else
    info "Next: open your IDE and run /sly.init to create the project lore."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

IDES=""
VERSION="${SLY_VERSION:-}"
TARGET="."
SOURCE=""
ACTION="install"

while [ $# -gt 0 ]; do
  case "$1" in
    --ide) IDES="${2:?--ide requires a value}"; shift 2 ;;
    --ide=*) IDES="${1#*=}"; shift ;;
    --version) VERSION="${2:?--version requires a value}"; shift 2 ;;
    --version=*) VERSION="${1#*=}"; shift ;;
    --dir) TARGET="${2:?--dir requires a value}"; shift 2 ;;
    --dir=*) TARGET="${1#*=}"; shift ;;
    --source) SOURCE="${2:?--source requires a value}"; shift 2 ;;
    --source=*) SOURCE="${1#*=}"; shift ;;
    --uninstall) ACTION="uninstall"; shift ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown option '$1' (see --help)" ;;
  esac
done

[ -d "$TARGET" ] || die "folder '$TARGET' does not exist"
TARGET="$(cd "$TARGET" && pwd)"
SLY_DIR="$TARGET/.sly"
MANIFEST="$SLY_DIR/.manifest"

case "$ACTION" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac

#!/usr/bin/env bash
# Deppend — Lightweight, language-agnostic Git dependency fetcher
# Copyright 2026 Kevin Mackey. All Rights Reserved.
# Docs:    https://github.com/Malkalypse/Deppend
# License: https://github.com/Malkalypse/Deppend/blob/main/LICENSE.md

set -euo pipefail

BASE_URL="https://github.com/Malkalypse"
TARGET_DIR="dependencies"
UPDATE=0
SPECS=()

usage() {
	cat <<'EOF'
Usage: deppend [options] <RepoOrUrl> [...]

Options:
  -b, --base <url>    Override base Git URL (default: https://github.com/Malkalypse)
  -d, --dir <path>    Override install directory (default: ./dependencies)
  -u, --update        Pull latest changes for already-installed dependencies
  -h, --help          Show this help message

Docs: https://github.com/Malkalypse/Deppend
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		-b|--base)
			BASE_URL="${2:?Missing value for $1}"
			shift 2
			;;
		--base=*)
			BASE_URL="${1#*=}"
			shift
			;;
		-d|--dir)
			TARGET_DIR="${2:?Missing value for $1}"
			shift 2
			;;
		--dir=*)
			TARGET_DIR="${1#*=}"
			shift
			;;
		-u|--update)
			UPDATE=1
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		--)
			shift
			while [ "$#" -gt 0 ]; do
				SPECS+=("$1")
				shift
			done
			;;
		-*)
			echo "Unknown option: $1" >&2
			usage >&2
			exit 1
			;;
		*)
			SPECS+=("$1")
			shift
			;;
	esac
done

# Fall back to ./deps.txt if no repo arguments were passed
if [ "${#SPECS[@]}" -eq 0 ] && [ "$UPDATE" -eq 0 ] && [ -f "deps.txt" ]; then
	while IFS= read -r line || [ -n "$line" ]; do
		line="${line%$'\r'}"
		line="${line#"${line%%[![:space:]]*}"}"
		[ -z "$line" ] && continue
		case "$line" in
			\#*) continue ;;
		esac
		SPECS+=("$line")
	done < "deps.txt"
fi

if [ "${#SPECS[@]}" -eq 0 ] && [ "$UPDATE" -eq 0 ]; then
	usage >&2
	exit 1
fi

mkdir -p "$TARGET_DIR"
ROOT_DIR="$(cd "$TARGET_DIR" && pwd)"
VISITED="|"

install_repo() {
	local spec="$1"
	local url name target deps_file line

	# Trim leading/trailing whitespace
	spec="${spec#"${spec%%[![:space:]]*}"}"
	spec="${spec%"${spec##*[![:space:]]}"}"
	[ -z "$spec" ] && return 0

	case "$spec" in
		*"://"*|git@*)
			url="$spec"
			;;
		*)
			url="${BASE_URL%/}/${spec}.git"
			;;
	esac

	url="${url%/}"
	name="${url##*/}"
	name="${name%.git}"

	case "$VISITED" in
		*"|$name|"*) return 0 ;;
	esac
	VISITED="${VISITED}${name}|"

	target="${ROOT_DIR}/${name}"

	if [ -d "$target" ]; then
		if [ "$UPDATE" -eq 1 ]; then
			echo "Updating $name..."
			git -C "$target" pull --ff-only </dev/null
		else
			echo "Skipping $name (already installed)"
		fi
	else
		echo "Cloning $name..."
		git clone "$url" "$target" </dev/null
	fi

	deps_file="${target}/deps.txt"
	if [ -f "$deps_file" ]; then
		while IFS= read -r line || [ -n "$line" ]; do
			line="${line%$'\r'}"
			line="${line#"${line%%[![:space:]]*}"}"
			[ -z "$line" ] && continue
			case "$line" in
				\#*) continue ;;
			esac
			install_repo "$line"
		done < "$deps_file"
	fi
}

# If --update is run with no repo args, update all installed siblings
if [ "${#SPECS[@]}" -eq 0 ] && [ "$UPDATE" -eq 1 ]; then
	for gitdir in "$ROOT_DIR"/*/.git; do
		[ -d "$gitdir" ] || continue
		SPECS+=("$(basename "$(dirname "$gitdir")")")
	done
fi

if [ "${#SPECS[@]}" -gt 0 ]; then
	for spec in "${SPECS[@]}"; do
		install_repo "$spec"
	done
fi

# Auto-generate autoload.php if any installed dependency has PHP files under src/
AUTOLOAD="${ROOT_DIR}/autoload.php"
if [ ! -f "$AUTOLOAD" ]; then
	has_php=0
	for src_dir in "$ROOT_DIR"/*/src; do
		[ -d "$src_dir" ] || continue
		if [ -n "$(find "$src_dir" -type f -name '*.php' -print)" ]; then
			has_php=1
			break
		fi
	done

	if [ "$has_php" -eq 1 ]; then
		cat > "$AUTOLOAD" <<'PHP'
<?php
spl_autoload_register( function ( string $class ): void {
	static $dirs = null;
	$dirs ??= glob( __DIR__ . '/*/src', GLOB_ONLYDIR ) ?: [];
	$rel = str_replace( '\\', '/', $class ) . '.php';
	foreach ( $dirs as $dir ) {
		if ( is_file( $file = $dir . '/' . $rel ) ) {
			require_once $file;
			return;
		}
	}
} );
PHP
		echo "Created ${TARGET_DIR}/autoload.php"
	fi
fi
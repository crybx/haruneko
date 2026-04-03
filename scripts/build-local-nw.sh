#!/usr/bin/env bash

set -euo pipefail

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    fi
}

extract_zip() {
    local archive_file="$1"
    local destination_dir="$2"

    rm -rf "$destination_dir"
    mkdir -p "$destination_dir"

    if command -v unzip >/dev/null 2>&1; then
        local rc=0
        unzip -q "$archive_file" -d "$destination_dir" || rc=$?
        # exit code 1 = warnings only (e.g. backslash path separators), extraction succeeded
        if (( rc > 1 )); then return "$rc"; fi
        return 0
    fi

    if command -v powershell >/dev/null 2>&1; then
        powershell -NoProfile -Command \
            "Expand-Archive -LiteralPath '$archive_file' -DestinationPath '$destination_dir'"
        return
    fi

    printf 'Unable to extract %s: neither unzip nor powershell is available\n' "$archive_file" >&2
    exit 1
}

install_bundle() {
    local archive_file="$1"
    local install_root="$2"
    local extract_dir="$install_root/.extract"

    rm -rf "$extract_dir"
    mkdir -p "$extract_dir"
    extract_zip "$archive_file" "$extract_dir"

    local extracted_app_dir
    extracted_app_dir="$(find "$extract_dir" -maxdepth 1 -mindepth 1 -type d | head -n 1 || true)"
    if [[ -z "$extracted_app_dir" ]]; then
        printf 'Expected extracted app directory not found in %s\n' "$extract_dir" >&2
        exit 1
    fi

    # Preserve userdata across reinstalls
    local preserved_userdata="$install_root/.userdata"
    rm -rf "$preserved_userdata"
    if [[ -d "$install_root/userdata" ]]; then
        mv "$install_root/userdata" "$preserved_userdata"
    fi

    find "$install_root" -mindepth 1 -maxdepth 1 \
        ! -name '.extract' \
        ! -name '.userdata' \
        -exec rm -rf {} +

    cp -a "$extracted_app_dir"/. "$install_root/"
    rm -rf "$extract_dir"

    if [[ -d "$preserved_userdata" ]]; then
        rm -rf "$install_root/userdata"
        mv "$preserved_userdata" "$install_root/userdata"
    fi
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_dir="$(cd "$script_dir/.." && pwd -P)"
nw_dir="$repo_dir/app/nw"

require_command npm
require_command node

app_name="$(cd "$nw_dir" && node -p "require('./package.json').name")"

case "$(uname -m)" in
    x86_64|amd64)  target_arch="x64" ;;
    i386|i686)     target_arch="ia32" ;;
    arm64|aarch64) target_arch="arm64" ;;
    *)
        printf 'Unsupported machine architecture: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

printf 'Building workspaces...\n'
(cd "$repo_dir" && npm run build --workspaces)

printf 'Bundling NW.js app...\n'
(cd "$repo_dir" && npm run bundle --workspace=app/nw)

shopt -s nullglob
artifacts=("$nw_dir"/bundle/"$app_name"-*-win-"$target_arch".zip)
shopt -u nullglob

if [[ "${#artifacts[@]}" -eq 0 ]]; then
    printf 'No bundle artifact found for architecture %s in %s\n' "$target_arch" "$nw_dir/bundle" >&2
    exit 1
fi

artifact_file="$(printf '%s\n' "${artifacts[@]}" | sort -V | tail -n 1)"
run_dir="$nw_dir/.local-run/current"

printf 'Installing %s...\n' "$(basename "$artifact_file")"
install_bundle "$artifact_file" "$run_dir"

printf 'Done. Launch with launch-local-nw.cmd\n'

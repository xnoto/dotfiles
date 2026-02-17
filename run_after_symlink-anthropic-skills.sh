#!/bin/bash
# Symlink skills from ~/git/anthropics/skills into the opencode skills directory.
# Skips skills that already exist as real (non-symlink) directories to avoid
# clobbering custom skills from xnoto/opencode-config.
set -euo pipefail

UPSTREAM_SKILLS="${HOME}/git/anthropics/skills/skills"
TARGET_SKILLS="${HOME}/.config/opencode/skills"

if [ ! -d "${UPSTREAM_SKILLS}" ]; then
    echo "anthropic-skills: upstream not found at ${UPSTREAM_SKILLS}, skipping"
    exit 0
fi

mkdir -p "${TARGET_SKILLS}"

# Create symlinks for each upstream skill
for skill_dir in "${UPSTREAM_SKILLS}"/*/; do
    [ -d "${skill_dir}" ] || continue
    skill_name="$(basename "${skill_dir}")"
    target="${TARGET_SKILLS}/${skill_name}"

    # Skip if a real (non-symlink) directory already exists
    if [ -d "${target}" ] && [ ! -L "${target}" ]; then
        continue
    fi

    # Create or update symlink
    ln -sfn "${skill_dir%/}" "${target}"
done

# Clean stale symlinks pointing to removed upstream skills
for link in "${TARGET_SKILLS}"/*/; do
    [ -L "${link%/}" ] || continue
    if [ ! -e "${link%/}" ]; then
        rm -f "${link%/}"
    fi
done

#!/usr/bin/env bash
set -euo pipefail

VERSION_FILE="${1:-VERSION}"
BASE_VERSION="$(tr -d ' \n\r\t' < "$VERSION_FILE")"

if [[ ! "$BASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::VERSION must be strict SemVer X.Y.Z. Got: '$BASE_VERSION'"
  exit 1
fi

git fetch --tags --force

LAST_STABLE="$({ git tag -l | sed 's/^v//' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' || true; } | sort -V | tail -n 1)"

echo "BASE_VERSION=$BASE_VERSION"
echo "LAST_STABLE=$LAST_STABLE"

if [[ -n "$LAST_STABLE" ]]; then
  if ! dpkg --compare-versions "$BASE_VERSION" ge "$LAST_STABLE"; then
    echo "::error::VERSION ($BASE_VERSION) is lower than latest stable tag ($LAST_STABLE)."
    exit 1
  fi
fi

if [[ -n "$LAST_STABLE" && "$BASE_VERSION" == "$LAST_STABLE" ]]; then
  IFS='.' read -r major minor patch <<< "$BASE_VERSION"
  patch=$((patch + 1))
  BASE_VERSION="${major}.${minor}.${patch}"
  printf '%s\n' "$BASE_VERSION" > "$VERSION_FILE"

  git add "$VERSION_FILE"
  git commit -m "ci: bump VERSION to $BASE_VERSION [skip ci]"
  git push origin HEAD:develop
fi

echo "BASE_VERSION=$BASE_VERSION" >> "$GITHUB_ENV"
echo "DEV_VERSION=${BASE_VERSION}-dev.${GITHUB_RUN_NUMBER}" >> "$GITHUB_ENV"
echo "LAST_STABLE=$LAST_STABLE" >> "$GITHUB_ENV"
#!/usr/bin/env bash
set -euo pipefail

ROOT="uStepperHardware"
OUT="uStepperHardware_${BASE_VERSION}.zip"

stage="$(mktemp -d)"
mkdir -p "${stage}/${ROOT}"

shopt -s dotglob nullglob
cp -R uStepperHardware/* "${stage}/${ROOT}/"
sed -i -E "s/^version=.*/version=${BASE_VERSION}/" "${stage}/${ROOT}/platform.txt"

(
  cd "$stage"
  zip -qr "$OLDPWD/$OUT" "$ROOT"
)

sha256="$(sha256sum "$OUT" | awk '{print $1}')"
size="$(stat -c%s "$OUT")"

echo "TARBALL=$OUT" >> "$GITHUB_ENV"
echo "SHA256=$sha256" >> "$GITHUB_ENV"
echo "SIZE=$size" >> "$GITHUB_ENV"

rm -rf "$stage"
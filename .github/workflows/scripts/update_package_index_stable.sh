#!/usr/bin/env bash
set -euo pipefail

PACKAGE_INDEX="package_ustepper_index.json"
URL="https://github.com/uStepper/uStepperHardware/releases/download/v${BASE_VERSION}/${TARBALL}"

tmp="$(mktemp)"
jq \
  --arg ver "$BASE_VERSION" \
  --arg url "$URL" \
  --arg file "$TARBALL" \
  --arg sha "SHA-256:${SHA256}" \
  --arg size "$SIZE" '
  .packages[0].platforms as $plats
  | ($plats | map(select(.version | test("-dev\\.") | not))) as $stable
  | ($stable | last) as $template
  | if $template == null then
      error("No stable platform entries found to use as template.")
    else
      ({
        name: $template.name,
        architecture: $template.architecture,
        version: $ver,
        category: $template.category,
        url: $url,
        archiveFileName: $file,
        checksum: $sha,
        size: $size,
        boards: $template.boards,
        toolsDependencies: $template.toolsDependencies
      }) as $new
      | .packages[0].platforms = (([$new] + ($stable | map(select(.version != $ver)))))
    end
' "$PACKAGE_INDEX" > "$tmp"
mv "$tmp" "$PACKAGE_INDEX"
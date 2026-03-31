#!/usr/bin/env bash
set -euo pipefail

PACKAGE_INDEX="package_ustepper_index.json"
URL="https://github.com/uStepper/uStepperHardware/releases/download/v${DEV_VERSION}/${TARBALL}"

tmp="$(mktemp)"
jq \
  --arg ver "$DEV_VERSION" \
  --arg url "$URL" \
  --arg file "$TARBALL" \
  --arg sha "SHA-256:${SHA256}" \
  --arg size "$SIZE" \
  --arg stable "$BASE_VERSION" '
  .packages[0].platforms as $plats
  | (($plats | map(select(.version == $stable and (.version | test("-dev\\.") | not))))[0]
      // ($plats | map(select(.version | test("-dev\\.") | not)) | last)) as $template
  | if $template == null then
      error("No stable platform entry found to use as template.")
    else
      .packages[0].platforms =
        ([{
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
        }] + ($plats | map(select(.version != $ver))))
    end
' "$PACKAGE_INDEX" > "$tmp"
mv "$tmp" "$PACKAGE_INDEX"
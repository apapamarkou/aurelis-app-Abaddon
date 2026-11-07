#!/bin/sh

set -eu

OUTDIR="${OUTDIR:-./dist}"
LINKS_FILE="$OUTDIR/app.links"
REPO="${GITHUB_REPOSITORY:-}"
TAG="${VERSION:-}"

mkdir -p "$OUTDIR"

dedup() {
    echo "$1" | tr ';' '\n' | grep -v '^$' | sort -u | tr '\n' ';' | sed 's/^;//;s/;$//'
}

TMP_FILE=$(mktemp)

# Download links
if [ -n "$REPO" ] && [ -n "$TAG" ]; then
    BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"

    appimage_links=""
    for f in "$OUTDIR"/*.AppImage; do
        [ -f "$f" ] || continue
        appimage_links="$appimage_links;${BASE_URL}/$(basename "$f")"
    done
    appimage_links=$(dedup "$appimage_links")
    [ -n "$appimage_links" ] && echo "AppImage: $appimage_links" >> "$TMP_FILE"

    sha_links=""
    for f in "$OUTDIR"/*.AppImage.sha256; do
        [ -f "$f" ] || continue
        sha_links="$sha_links;${BASE_URL}/$(basename "$f")"
    done
    sha_links=$(dedup "$sha_links")
    [ -n "$sha_links" ] && echo "Sha256: $sha_links" >> "$TMP_FILE"

    desktop_links=""
    for f in "$OUTDIR"/*.desktop; do
        [ -f "$f" ] || continue
        desktop_links="$desktop_links;${BASE_URL}/$(basename "$f")"
    done
    desktop_links=$(dedup "$desktop_links")
    [ -n "$desktop_links" ] && echo "Desktop: $desktop_links" >> "$TMP_FILE"

    icon_links=""
    for f in "$OUTDIR"/*.svg "$OUTDIR"/*.png; do
        [ -f "$f" ] || continue
        icon_links="$icon_links;${BASE_URL}/$(basename "$f")"
    done
    icon_links=$(dedup "$icon_links")
    [ -n "$icon_links" ] && echo "Icons: $icon_links" >> "$TMP_FILE"
fi

mv "$TMP_FILE" "$LINKS_FILE"
echo "Created: $LINKS_FILE"

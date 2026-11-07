#!/bin/sh

set -eu

OUTDIR="${OUTDIR:-./dist}"
APPDIR="${APPDIR:-./AppDir}"
INFO_FILE="$OUTDIR/app.info"

# Detect package name from env or first binary in AppDir/bin
if [ -z "${PACKAGE_NAME:-}" ]; then
    PACKAGE_NAME=$(find "$APPDIR/bin" -maxdepth 1 -type f 2>/dev/null | head -1 | xargs basename 2>/dev/null || true)
fi

mkdir -p "$OUTDIR"

TMP_FILE=$(mktemp)

if [ -n "$PACKAGE_NAME" ] && command -v pacman > /dev/null 2>&1; then
    pacman -Sii "$PACKAGE_NAME" > "$TMP_FILE" 2>/dev/null || true
fi

OUT=$(mktemp)

{
    name=$(grep -E '^Name\s*:' "$TMP_FILE" | head -1 | cut -d':' -f2- | sed 's/^ *//')
    [ -n "$name" ] && echo "Name: $name"

    version=$(grep -E '^Version\s*:' "$TMP_FILE" | head -1 | cut -d':' -f2- | sed 's/^ *//')
    [ -n "$version" ] && echo "Version: $version"

    desc=$(grep -E '^Description\s*:' "$TMP_FILE" | head -1 | cut -d':' -f2- | sed 's/^ *//')
    [ -n "$desc" ] && echo "ShortDescription: $desc"

    arch=$(grep -E '^Architecture\s*:' "$TMP_FILE" | head -1 | cut -d':' -f2- | sed 's/^ *//')
    [ -n "$arch" ] && echo "Architecture: $arch"

    url=$(grep -E '^URL\s*:' "$TMP_FILE" | head -1 | cut -d':' -f2- | sed 's/^ *//')
    [ -n "$url" ] && echo "Source: https:$url"

    licenses=$(grep -E '^Licenses\s*:' "$TMP_FILE" | head -1 | cut -d':' -f2- | sed 's/^ *//')
    [ -n "$licenses" ] && echo "Licenses: $licenses"
} > "$OUT"

rm -f "$TMP_FILE"

# Collect desktop-derived fields
dedup() {
    echo "$1" | tr ';' '\n' | grep -v '^$' | sort -u | tr '\n' ';' | sed 's/^;//;s/;//'
}

all_provides=""
all_categories=""
all_execs=""

desktop_list=$(mktemp)
find "$OUTDIR" -name "*.desktop" -type f 2>/dev/null > "$desktop_list"

while read -r desktop_file; do
    [ -z "$desktop_file" ] && continue
    dname=$(grep -E '^Name=' "$desktop_file" | head -1 | cut -d'=' -f2-)
    [ -n "$dname" ] && all_provides="$all_provides;$dname"
    cats=$(grep -E '^Categories=' "$desktop_file" | head -1 | cut -d'=' -f2- | sed 's/;$//')
    [ -n "$cats" ] && all_categories="$all_categories;$cats"
    exec_cmd=$(grep -E '^Exec=' "$desktop_file" | head -1 | cut -d'=' -f2- | awk '{print $1}')
    [ -n "$exec_cmd" ] && all_execs="$all_execs;$(basename "$exec_cmd")"
done < "$desktop_list"
rm -f "$desktop_list"

unique_provides=$(dedup "$all_provides")
unique_categories=$(dedup "$all_categories")
unique_execs=$(dedup "$all_execs")

[ -n "$unique_provides" ]   && echo "Provide: $unique_provides"      >> "$OUT"
[ -n "$unique_categories" ] && echo "Categories: $unique_categories" >> "$OUT"
[ -n "$unique_execs" ]      && echo "Bin: $unique_execs"             >> "$OUT"

mv "$OUT" "$INFO_FILE"
echo "Created: $INFO_FILE"

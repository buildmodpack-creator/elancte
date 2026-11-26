#!/usr/bin/env bash
# Dumps public/protected API signatures of the Loom-mapped Minecraft jar (Mojang names).
# Used only as a porting reference; prints the result to the job log.
set -u
TMP="${RUNNER_TEMP:-/tmp}"
OUT="${GITHUB_WORKSPACE:-$PWD}/api-dump.txt"

JAR=""
while IFS= read -r j; do
  if unzip -Z1 "$j" 2>/dev/null | grep -q '^net/minecraft/client/Minecraft\.class$'; then
    JAR="$j"
    break
  fi
done < <(find "$HOME/.gradle" -name '*.jar' 2>/dev/null)

if [ -z "$JAR" ]; then
  echo "Minecraft jar not found under ~/.gradle"
  exit 0
fi
echo "Minecraft jar: $JAR"

unzip -Z1 "$JAR" \
  | grep -E '^(net/minecraft/client|com/mojang/blaze3d)/.*\.class$' \
  | grep -v 'module-info' \
  | sed -E 's/\.class$//; s#/#.#g' > "$TMP/api-classes.txt"
echo "classes to dump: $(wc -l < "$TMP/api-classes.txt")"

: > "$OUT"
xargs -a "$TMP/api-classes.txt" -n 150 javap -public -protected -cp "$JAR" >> "$OUT" 2>/dev/null
echo "dump lines: $(wc -l < "$OUT")  bytes: $(wc -c < "$OUT")"
cat "$OUT"

#!/usr/bin/env bash
# Gera o APK de release e publica na VM; o app avisa a nova versao sozinho.
#
#   deploy/oracle/publicar-apk.sh "o que mudou"               # atualizacao opcional
#   deploy/oracle/publicar-apk.sh --obrigatoria "o que mudou" # versoes antigas precisam atualizar
#
# Antes, aumente o numero depois do "+" em `version:` no frontend/pubspec.yaml.
set -euo pipefail

SERVER="${CYSVET_SERVER:-ubuntu@137.131.146.81}"
DOMAIN="${CYSVET_DOMAIN:-cysvet.duckdns.org}"
REMOTE_DIR="cysvet_app/deploy/oracle/app"

required=false
if [ "${1:-}" = "--obrigatoria" ]; then
  required=true
  shift
fi
notes="${1:-}"

root="$(cd "$(dirname "$0")/../.." && pwd)"
version_line="$(grep -E '^version:' "$root/frontend/pubspec.yaml")"
version_name="$(echo "$version_line" | sed -E 's/^version: *([^+]+)\+.*/\1/')"
version_code="$(echo "$version_line" | sed -E 's/^version: *[^+]+\+([0-9]+).*/\1/')"

published="$(curl -fsS "https://$DOMAIN/app/versao.json" 2>/dev/null || echo '{}')"
read -r published_code published_min < <(echo "$published" | python -c \
  "import json,sys; d=json.load(sys.stdin); print(d.get('versionCode',0), d.get('minVersionCode',0))")

if [ "$version_code" -le "$published_code" ]; then
  echo "A versao $version_code nao e maior que a publicada ($published_code)."
  echo "Aumente o numero depois do '+' em version: no frontend/pubspec.yaml."
  exit 1
fi

min_code="$published_min"
if [ "$required" = true ]; then
  min_code="$version_code"
fi

echo "Gerando CYSVET $version_name ($version_code)..."
(cd "$root/frontend" && flutter build apk --release --dart-define=API_BASE_URL="https://$DOMAIN")

apk="$root/frontend/build/app/outputs/flutter-apk/app-release.apk"
apk_name="cysvet-$version_code.apk"
sha="$(sha256sum "$apk" | cut -d' ' -f1)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

NOTES="$notes" python - "$tmp/versao.json" "$version_code" "$version_name" "$min_code" "$apk_name" "$sha" <<'EOF'
import json, os, sys
path, code, name, min_code, apk, sha = sys.argv[1:]
with open(path, "w", encoding="utf-8") as f:
    json.dump({
        "versionCode": int(code),
        "versionName": name,
        "minVersionCode": int(min_code),
        "apk": apk,
        "sha256": sha,
        "notas": os.environ.get("NOTES", ""),
    }, f, ensure_ascii=False, indent=2)
EOF

# O APK sobe antes do versao.json para o app nunca ver uma versao sem arquivo.
ssh "$SERVER" "mkdir -p ~/$REMOTE_DIR"
scp "$apk" "$SERVER:$REMOTE_DIR/$apk_name"
scp "$tmp/versao.json" "$SERVER:$REMOTE_DIR/versao.json"
# Mantem so os 3 APKs mais recentes.
ssh "$SERVER" "cd ~/$REMOTE_DIR && ls -1t cysvet-*.apk | tail -n +4 | xargs -r rm -f"

copy_dir="$HOME/Desktop/CYSVET-APK"
mkdir -p "$copy_dir"
cp "$apk" "$copy_dir/cysvet.apk"

echo "Publicado: https://$DOMAIN/app/$apk_name (minimo $min_code)"

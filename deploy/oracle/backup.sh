#!/usr/bin/env sh
# Backup diario do banco (agende no cron da VM). Mantem os ultimos 14 dias.
#   0 3 * * * sh /home/ubuntu/cysvet_app/deploy/oracle/backup.sh >> /home/ubuntu/cysvet-backup.log 2>&1
set -eu

cd "$(dirname "$0")"
mkdir -p backups
arquivo="backups/cysvet-$(date +%Y%m%d-%H%M%S).sql.gz"

docker compose exec -T mysql sh -c \
  'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction --routines --triggers cysvet' \
  | gzip > "$arquivo"

find backups -name 'cysvet-*.sql.gz' -mtime +14 -delete
echo "$(date -Iseconds) backup ok: $arquivo"

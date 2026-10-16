#!/bin/bash
# Loads the sample database from database/ (mounted at /seed) into MariaDB.
# Runs once, from the MariaDB image's /docker-entrypoint-initdb.d on first start.
# Any *.sql files mounted after it in /docker-entrypoint-initdb.d (e.g. test fixtures) run next.
set -euo pipefail

sql() { mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" --default-character-set=utf8mb4 openbenc_benches "$@"; }

for table in users licences media_types tags banned_users benches media tag_map merged_benches; do
  echo "Loading $table"
  sql < "/seed/openbenc_benches_table_${table}.sql"
done

# benches_history is ~60MB of edit history the API doesn't read; create it empty.
# mastodon_apps isn't published at all.
sql <<'SQL'
CREATE TABLE `benches_history` (
  `benchID` bigint(20) NOT NULL,
  `latitude` float(10,6) NOT NULL,
  `longitude` float(10,6) NOT NULL,
  `address` text NOT NULL,
  `inscription` text DEFAULT NULL,
  `description` text NOT NULL,
  `present` tinyint(1) NOT NULL,
  `published` tinyint(1) NOT NULL,
  `added` datetime NOT NULL DEFAULT current_timestamp(),
  `userID` bigint(20) NOT NULL,
  `osmID` bigint(20) UNSIGNED DEFAULT NULL,
  `changed` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE `mastodon_apps` (
  `domain_name` varchar(255) NOT NULL,
  `client_id` text NOT NULL,
  `client_secret` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SQL

echo "Loading indexes and constraints"
# Some table dumps already declare their keys, so skip statements that collide.
sql --force < /seed/openbenc_benches_extra.sql 2>&1 | grep -v -e "^-*$" -e "^ALTER\\|^  " || true

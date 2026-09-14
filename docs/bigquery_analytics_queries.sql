-- ============================================================================
-- BeyTourney HIDEOUT — BigQuery Analytics Queries (untuk Looker Studio)
-- ============================================================================
-- Sumber : Firestore BigQuery Export extension (firebase/firestore-bigquery-export)
-- Dataset: hideout_analytics (lihat firebase_patch/ext.bigquery.params.json)
-- Tabel  : <TABLE_PREFIX>_<collection>_raw  → contoh: bq_users_raw
--          (kalau TABLE_PREFIX di params kamu beda, ganti bq_ di bawah)
-- Struktur kolom extension: event_id, document_name, timestamp, operation, data (JSON)
-- Tip timestamp: data.createdAt berupa JSON; untuk objek {_seconds:...} gunakan:
--   TIMESTAMP_MILLIS(CAST(JSON_VALUE(data, '$.createdAt._seconds') AS INT64))
--   Untuk string ISO: TIMESTAMP(JSON_VALUE(data, '$.createdAt'))
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TOTAL PENGGUNA & DISTRIBUSI ROLE
-- ----------------------------------------------------------------------------
SELECT
  COUNT(*) AS total_users,
  COUNTIF(JSON_VALUE(data, '$.isActive') = 'true') AS active_users,
  COUNTIF(JSON_EXTRACT_SCALAR(data, '$.roles[0]') = 'judge') AS judges,
  COUNTIF(JSON_EXTRACT_SCALAR(data, '$.roles[0]') = 'community_admin') AS community_leads,
  COUNTIF(JSON_EXTRACT_SCALAR(data, '$.roles[0]') = 'super_admin') AS super_admins
FROM `hideout_analytics.bq_users_raw`
WHERE operation = 'CREATE'
  AND TIMESTAMP(timestamp) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY);

-- ----------------------------------------------------------------------------
-- 2. LEADERBOARD ELO — TOP 50
-- ----------------------------------------------------------------------------
SELECT
  document_name AS uid,
  JSON_VALUE(data, '$.displayName') AS player_name,
  CAST(JSON_VALUE(data, '$.eloRating') AS INT64) AS elo,
  CAST(JSON_VALUE(data, '$.totalWins') AS INT64) AS wins,
  CAST(JSON_VALUE(data, '$.totalLosses') AS INT64) AS losses,
  CAST(JSON_VALUE(data, '$.totalMatches') AS INT64) AS matches_played
FROM `hideout_analytics.bq_users_raw`
WHERE operation = 'CREATE'
QUALIFY ROW_NUMBER() OVER (PARTITION BY document_name ORDER BY timestamp DESC) = 1
ORDER BY elo DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- 3. TURNAMEN PER KOTA & STATUS
-- ----------------------------------------------------------------------------
SELECT
  JSON_VALUE(data, '$.city') AS city,
  JSON_VALUE(data, '$.status') AS status,
  COUNT(*) AS tournaments,
  SUM(CAST(JSON_VALUE(data, '$.maxParticipants') AS INT64)) AS total_slots,
  SUM(CAST(JSON_VALUE(data, '$.currentParticipantCount') AS INT64)) AS total_participants
FROM `hideout_analytics.bq_tournaments_raw`
WHERE operation = 'CREATE'
GROUP BY city, status
ORDER BY city, status;

-- ----------------------------------------------------------------------------
-- 4. FUNNEL REGISTRASI PER TURNAMEN (pendingPayment → active)
-- ----------------------------------------------------------------------------
SELECT
  SPLIT(document_name, '/')[SAFE_OFFSET(1)] AS tournament_id,
  COUNT(*) AS total_registrations,
  COUNTIF(JSON_VALUE(data, '$.registrationStatus') = 'pendingPayment') AS pending_payment,
  COUNTIF(JSON_VALUE(data, '$.paymentStatus') = 'paid') AS paid,
  COUNTIF(JSON_VALUE(data, '$.registrationStatus') = 'active') AS active,
  COUNTIF(JSON_VALUE(data, '$.checkInStatus') = 'checked_in') AS checked_in
FROM `hideout_analytics.bq_registrations_raw`
WHERE operation = 'CREATE'
GROUP BY tournament_id
ORDER BY total_registrations DESC;

-- ----------------------------------------------------------------------------
-- 5. REVENUE PER TURNAMEN (payment status paid)
-- ----------------------------------------------------------------------------
SELECT
  SPLIT(document_name, '/')[SAFE_OFFSET(1)] AS tournament_id,
  COUNTIF(JSON_VALUE(data, '$.status') = 'paid') AS paid_count,
  SAFE_DIVIDE(
    SUM(CASE WHEN JSON_VALUE(data, '$.status') = 'paid'
             THEN CAST(JSON_VALUE(data, '$.amount') AS INT64) END),
    1000000) AS revenue_juta_rupiah
FROM `hideout_analytics.bq_payments_raw`
WHERE operation = 'CREATE'
GROUP BY tournament_id
ORDER BY revenue_juta_rupiah DESC;

-- ----------------------------------------------------------------------------
-- 6. KOMPONEN PALING BANYAK DIPAKAI (dari combos deck)
--    Deck doc: combos[] → {blade, assistBlade, overBlade, lockChip, ratchet, bit}
-- ----------------------------------------------------------------------------
SELECT
  JSON_VALUE(slot, '$.partId') AS part_id,
  JSON_VALUE(slot, '$.name') AS part_name,
  JSON_VALUE(slot, '$.category') AS category,
  COUNT(*) AS usage_count
FROM `hideout_analytics.bq_decks_raw` d,
  UNNEST(JSON_QUERY_ARRAY(d.data, '$.combos')) AS combo,
  UNNEST([
    JSON_QUERY(combo, '$.blade'),
    JSON_QUERY(combo, '$.assistBlade'),
    JSON_QUERY(combo, '$.overBlade'),
    JSON_QUERY(combo, '$.lockChip'),
    JSON_QUERY(combo, '$.ratchet'),
    JSON_QUERY(combo, '$.bit')
  ]) AS slot
WHERE d.operation = 'CREATE'
  AND JSON_VALUE(slot, '$.partId') IS NOT NULL
GROUP BY part_id, part_name, category
ORDER BY usage_count DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- 7. AKTIVITAS JURI (jumlah match selesai per juri)
-- ----------------------------------------------------------------------------
SELECT
  JSON_VALUE(data, '$.judgeId') AS judge_id,
  COUNT(*) AS matches_completed,
  COUNTIF(JSON_VALUE(data, '$.status') = 'completed') AS finished
FROM `hideout_analytics.bq_matches_raw`
WHERE operation = 'CREATE'
  AND JSON_VALUE(data, '$.judgeId') IS NOT NULL
GROUP BY judge_id
ORDER BY matches_completed DESC;

-- ----------------------------------------------------------------------------
-- 8. PERTUMBUHAN USER PER BULAN
-- ----------------------------------------------------------------------------
SELECT
  DATE_TRUNC(DATE(TIMESTAMP(timestamp)), MONTH) AS month,
  COUNT(*) AS new_users
FROM `hideout_analytics.bq_users_raw`
WHERE operation = 'CREATE'
GROUP BY month
ORDER BY month;

-- ----------------------------------------------------------------------------
-- 9. STATUS MATCH (progres bracket)
-- ----------------------------------------------------------------------------
SELECT
  JSON_VALUE(data, '$.status') AS status,
  COUNT(*) AS total
FROM `hideout_analytics.bq_matches_raw`
WHERE operation = 'CREATE'
GROUP BY status
ORDER BY total DESC;

-- ----------------------------------------------------------------------------
-- 10. APLIKASI KOMUNITAS (funnel approval)
-- ----------------------------------------------------------------------------
SELECT
  JSON_VALUE(data, '$.status') AS status,
  COUNT(*) AS applications,
  COUNTIF(JSON_VALUE(data, '$.status') = 'approved') AS approved,
  COUNTIF(JSON_VALUE(data, '$.status') = 'rejected') AS rejected
FROM `hideout_analytics.bq_communityApplications_raw`
WHERE operation = 'CREATE'
GROUP BY status;

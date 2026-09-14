-- ============================================================================
-- BeyTourney HIDEOUT — Draft Schema PostgreSQL (Supabase / self-host)
-- Status: DRAFT untuk fase migrasi dari Firestore. Belum diterapkan.
-- Target: PostgreSQL 15+ (Supabase atau VPS)
-- Catatan: Firestore collection → tabel; nested path → kolom FK.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS citext;     -- email case-insensitive

-- ---------------------------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------------------------
CREATE TYPE user_role        AS ENUM ('player', 'judge', 'community_admin', 'super_admin');
CREATE TYPE tournament_status AS ENUM ('draft', 'registrationOpen', 'ready', 'running', 'completed', 'cancelled');
CREATE TYPE bracket_type     AS ENUM ('singleElimination', 'doubleElimination', 'roundRobin');
CREATE TYPE registration_status AS ENUM ('pendingPayment', 'active', 'walkedOut', 'withdrawn');
CREATE TYPE payment_status   AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE withdrawal_status AS ENUM ('processing', 'completed', 'rejected');
CREATE TYPE match_status     AS ENUM ('queued', 'ready', 'live', 'completed', 'disputed');
CREATE TYPE application_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE deck_class       AS ENUM ('standard', 'cx', 'limited');

-- ---------------------------------------------------------------------------
-- USERS  (users/{uid})
-- ---------------------------------------------------------------------------
CREATE TABLE users (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid   TEXT UNIQUE,                 -- map ke Firebase Auth uid
  display_name   TEXT NOT NULL DEFAULT '',
  email          CITEXT NOT NULL UNIQUE,
  region         TEXT,
  elo_rating     INT  NOT NULL DEFAULT 1000,
  total_wins     INT  NOT NULL DEFAULT 0,
  total_losses   INT  NOT NULL DEFAULT 0,
  total_matches  INT  NOT NULL DEFAULT 0,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  is_qr_activated BOOLEAN NOT NULL DEFAULT FALSE,
  roles          user_role[] NOT NULL DEFAULT ARRAY['player'::user_role],
  banned_by      UUID REFERENCES users(id),
  banned_at      TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Multi-role query cepat (capabilities: player selalu ada)
CREATE INDEX idx_users_roles      ON users USING GIN (roles);
CREATE INDEX idx_users_elo        ON users (elo_rating DESC);
CREATE INDEX idx_users_active     ON users (is_active);

-- Audit trail grant/revoke role (wajib: siapa, kapan, role apa)
CREATE TABLE role_audit_log (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  target_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  actor_user_id UUID REFERENCES users(id),
  action       TEXT NOT NULL CHECK (action IN ('grant', 'revoke')),
  role         user_role NOT NULL,
  reason       TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- COMMUNITIES  (communities/{id})
-- ---------------------------------------------------------------------------
CREATE TABLE communities (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  tag           TEXT,
  type          TEXT,
  city          TEXT,
  region        TEXT,
  website       TEXT,
  description   TEXT,
  leader_user_id UUID NOT NULL REFERENCES users(id),
  status        TEXT NOT NULL DEFAULT 'active',
  source_application_id UUID,
  member_count  INT NOT NULL DEFAULT 1,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE community_members (
  community_id UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role         TEXT NOT NULL DEFAULT 'member',   -- member | admin | leader
  joined_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (community_id, user_id)
);

CREATE TABLE community_applications (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id  UUID NOT NULL REFERENCES users(id),
  leader_user_id UUID NOT NULL REFERENCES users(id),
  community_name TEXT NOT NULL,
  city          TEXT,
  region        TEXT,
  website       TEXT,
  description   TEXT,
  status        application_status NOT NULL DEFAULT 'pending',
  reviewer_id   UUID REFERENCES users(id),
  community_id  UUID REFERENCES communities(id),
  rejection_reason TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at   TIMESTAMPTZ
);

-- ---------------------------------------------------------------------------
-- TOURNAMENTS  (tournaments/{id})
-- ---------------------------------------------------------------------------
CREATE TABLE tournaments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL,
  description           TEXT,
  status                tournament_status NOT NULL DEFAULT 'draft',
  bracket_type          bracket_type NOT NULL DEFAULT 'singleElimination',
  location              TEXT,
  city                  TEXT,
  region                TEXT,
  registration_fee      BIGINT NOT NULL DEFAULT 0,        -- rupiah
  max_participants      INT NOT NULL DEFAULT 32,
  current_participant_count INT NOT NULL DEFAULT 0,
  organizer_id          UUID NOT NULL REFERENCES users(id),
  start_at              TIMESTAMPTZ,
  registration_deadline TIMESTAMPTZ,
  winner_user_id        UUID REFERENCES users(id),
  winner_deck_name      TEXT,
  current_round_id      UUID,
  current_stage         TEXT,
  bracket_size          INT,
  top_cut               INT,
  round_robin           BOOLEAN NOT NULL DEFAULT FALSE,
  started_at            TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_tournaments_status ON tournaments (status);
CREATE INDEX idx_tournaments_city   ON tournaments (city);
CREATE INDEX idx_tournaments_org    ON tournaments (organizer_id);

-- Arena per tournament (dari arenaIds / judgeIds di wizard)
CREATE TABLE tournament_arenas (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  judge_ids    UUID[] NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Registrasi  (tournaments/{id}/registrations/{regId})
CREATE TABLE registrations (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id         UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  player_id             UUID NOT NULL REFERENCES users(id),
  payment_status        payment_status NOT NULL DEFAULT 'pending',
  registration_status   registration_status NOT NULL DEFAULT 'pendingPayment',
  check_in_status       TEXT NOT NULL DEFAULT 'not_checked_in',
  deck_verification_status TEXT NOT NULL DEFAULT 'pending',
  paid_at               TIMESTAMPTZ,
  activated_at          TIMESTAMPTZ,
  walk_out_at           TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tournament_id, player_id)          -- 1 player 1 tournament
);

CREATE INDEX idx_registrations_tournament ON registrations (tournament_id);
CREATE INDEX idx_registrations_player     ON registrations (player_id);

-- Pembayaran  (tournaments/{id}/payments/{payId})
CREATE TABLE payments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  player_id     UUID NOT NULL REFERENCES users(id),
  xendit_ref    TEXT UNIQUE,
  status        payment_status NOT NULL DEFAULT 'pending',
  amount        BIGINT NOT NULL DEFAULT 0,
  paid_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Withdrawal  (tournaments/{id}/withdrawals/{wdId})
CREATE TABLE withdrawals (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  requester_id  UUID NOT NULL REFERENCES users(id),
  amount        BIGINT NOT NULL,
  status        withdrawal_status NOT NULL DEFAULT 'processing',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- BRACKET  (rounds → matches → battles)
-- ---------------------------------------------------------------------------
CREATE TABLE rounds (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  index_no      INT NOT NULL,
  name          TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tournament_id, index_no)
);

CREATE TABLE matches (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  round_id      UUID NOT NULL REFERENCES rounds(id) ON DELETE CASCADE,
  arena_id      UUID REFERENCES tournament_arenas(id),
  judge_id      UUID REFERENCES users(id),
  player_a_id   UUID REFERENCES users(id),
  player_b_id   UUID REFERENCES users(id),
  status        match_status NOT NULL DEFAULT 'queued',
  winner_id     UUID REFERENCES users(id),
  winner_name   TEXT,
  final_score   TEXT,
  completed_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_matches_judge   ON matches (judge_id);
CREATE INDEX idx_matches_tournament ON matches (tournament_id);

CREATE TABLE battles (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id   UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  index_no   INT NOT NULL,
  winner_id  UUID REFERENCES users(id),
  score      TEXT,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- DECKS  (users/{uid}/decks/{deckId}) + parts catalog
-- ---------------------------------------------------------------------------
CREATE TABLE components (
  id          TEXT PRIMARY KEY,                 -- partId (beyparts.json)
  name        TEXT NOT NULL,
  category    TEXT NOT NULL,                    -- blade/ratchet/bit/...
  alias       TEXT,
  type        TEXT NOT NULL DEFAULT 'balance',
  line        TEXT,
  image       TEXT,
  attack      INT NOT NULL DEFAULT 0,
  defense     INT NOT NULL DEFAULT 0,
  stamina     INT NOT NULL DEFAULT 0,
  x_dash      INT NOT NULL DEFAULT 0,
  burst_resistance INT NOT NULL DEFAULT 0
);

CREATE TABLE decks (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  deck_class deck_class NOT NULL DEFAULT 'standard',
  tier       TEXT,
  legal      BOOLEAN NOT NULL DEFAULT TRUE,
  issues     TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE deck_parts (
  deck_id    UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
  combo_idx  INT NOT NULL,
  slot       TEXT NOT NULL CHECK (slot IN ('blade','assistBlade','overBlade','lockChip','ratchet','bit')),
  component_id TEXT NOT NULL REFERENCES components(id),
  PRIMARY KEY (deck_id, combo_idx, slot)
);

CREATE TABLE component_stats (
  component_id TEXT PRIMARY KEY REFERENCES components(id),
  usage_count  INT NOT NULL DEFAULT 0,
  win_count    INT NOT NULL DEFAULT 0,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- NOTIFICATIONS & UTIL
-- ---------------------------------------------------------------------------
CREATE TABLE notifications (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type         TEXT NOT NULL,
  title        TEXT,
  body         TEXT,
  is_read      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_recipient ON notifications (recipient_id, is_read);

-- ---------------------------------------------------------------------------
-- REALTIME (Supabase): publikasikan tabel untuk live updates
--   alter publication supabase_realtime add table matches, registrations,
--     tournaments, notifications;
-- ---------------------------------------------------------------------------
-- RLS (ringkas — setiap tabel perlu ENABLE ROW LEVEL SECURITY + policy):
--   users        : SELECT sendiri / admin; UPDATE sendiri tanpa role* / admin / community_admin(judge grant)
--   tournaments  : SELECT public; UPDATE organizer / admin / assigned judge
--   registrations: SELECT anggota; INSERT player sendiri; UPDATE organizer / assigned judge (check-in)
--   matches      : SELECT peserta+juri; UPDATE judge yg di-assign
--   payments     : SELECT pemilik / admin; tulis hanya backend (service role)
--   decks        : SELECT sendiri / judge; tulis pemilik
--   role grant/revoke: WAJIB via service role / fungsi backend (JANGAN dari client)
-- ---------------------------------------------------------------------------
-- STRATEGI ELO & BRACKET: hitung di backend (Cloud Run / Supabase Edge Function)
-- saat match selesai — transaksi: update matches + users.elo + component_stats.
-- ---------------------------------------------------------------------------

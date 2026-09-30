-- Slip catalog schema (Neon Postgres)
CREATE TABLE IF NOT EXISTS station_catalogs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS stations (
  id TEXT NOT NULL,
  catalog_id TEXT NOT NULL REFERENCES station_catalogs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  line TEXT NOT NULL DEFAULT '',
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  PRIMARY KEY (catalog_id, id)
);

CREATE INDEX IF NOT EXISTS idx_stations_catalog ON stations(catalog_id);

CREATE TABLE IF NOT EXISTS brands (
  id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  category TEXT NOT NULL,
  apple_style TEXT NOT NULL,
  required_fields JSONB NOT NULL DEFAULT '[]'::jsonb,
  optional_fields JSONB NOT NULL DEFAULT '[]'::jsonb,
  supports_locations BOOLEAN NOT NULL DEFAULT FALSE,
  supports_relevant_date BOOLEAN NOT NULL DEFAULT FALSE,
  accent_hint TEXT,
  station_catalog TEXT,
  summary TEXT,
  badge TEXT,
  icon_hint TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pass_build_events (
  id BIGSERIAL PRIMARY KEY,
  template_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  success BOOLEAN NOT NULL,
  error_code TEXT
);

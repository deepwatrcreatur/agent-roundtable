-- roundtable/priv/dolt/migrations/20260512_add_board_attempt_event_log.sql

CREATE TABLE IF NOT EXISTS work_attempt_events (
    id VARCHAR(255) PRIMARY KEY,
    attempt_id VARCHAR(255) NOT NULL,
    work_item_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    summary TEXT,
    metadata_json TEXT NOT NULL,
    created_at TEXT NOT NULL
);

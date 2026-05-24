-- roundtable/priv/dolt/migrations/20260512_add_board_execution_schema.sql

CREATE TABLE IF NOT EXISTS work_items (
    id VARCHAR(255) PRIMARY KEY,
    repo_ref TEXT NOT NULL,
    branch_ref TEXT,
    source_ref TEXT,
    title TEXT NOT NULL,
    task_type VARCHAR(64) NOT NULL,
    input_payload TEXT NOT NULL,
    surface_route TEXT,
    public_demo_id VARCHAR(255),
    evidence_links_json TEXT,
    desired_outcome TEXT,
    status VARCHAR(64) NOT NULL,
    priority INT NOT NULL DEFAULT 100,
    assignee_type VARCHAR(32),
    assignee_ref TEXT,
    workflow_ref VARCHAR(255),
    retry_policy TEXT,
    timeout_policy TEXT,
    hitl_policy TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    closed_at TEXT
);

CREATE TABLE IF NOT EXISTS work_attempts (
    id VARCHAR(255) PRIMARY KEY,
    work_item_id VARCHAR(255) NOT NULL,
    attempt_number INT NOT NULL,
    runtime_id VARCHAR(255) NOT NULL,
    agent_id VARCHAR(255) NOT NULL,
    status VARCHAR(64) NOT NULL,
    lease_expires_at TEXT,
    started_at TEXT NOT NULL,
    finished_at TEXT,
    exit_class VARCHAR(64),
    summary TEXT,
    error_excerpt TEXT,
    artifact_ref TEXT,
    UNIQUE KEY work_item_attempt_unique (work_item_id, attempt_number)
);

CREATE TABLE IF NOT EXISTS human_gates (
    id VARCHAR(255) PRIMARY KEY,
    work_item_id VARCHAR(255) NOT NULL,
    attempt_id VARCHAR(255),
    gate_type VARCHAR(64) NOT NULL,
    prompt TEXT NOT NULL,
    options_json TEXT NOT NULL,
    state VARCHAR(32) NOT NULL,
    decision_json TEXT,
    resolved_by VARCHAR(255),
    created_at TEXT NOT NULL,
    resolved_at TEXT
);

CREATE TABLE IF NOT EXISTS runtime_heartbeats (
    runtime_id VARCHAR(255) PRIMARY KEY,
    host_label TEXT NOT NULL,
    transport VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL,
    capabilities_json TEXT NOT NULL,
    last_seen_at TEXT NOT NULL,
    active_attempt_id VARCHAR(255),
    metadata_json TEXT NOT NULL
);

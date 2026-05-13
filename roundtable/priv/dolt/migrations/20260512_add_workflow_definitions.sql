-- roundtable/priv/dolt/migrations/20260512_add_workflow_definitions.sql

CREATE TABLE IF NOT EXISTS workflow_definitions (
    id VARCHAR(255) PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    task_types_json TEXT NOT NULL,
    runtime_requirements_json TEXT NOT NULL,
    retry_policy_json TEXT,
    timeout_policy_json TEXT,
    hitl_policy_json TEXT,
    resume_policy_json TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

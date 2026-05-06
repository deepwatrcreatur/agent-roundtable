-- roundtable/priv/dolt/migrations/20260504_add_tagging_schema.sql

CREATE TABLE IF NOT EXISTS tags (
    id VARCHAR(255) PRIMARY KEY,
    kind VARCHAR(50) NOT NULL, -- 'topical', 'governance', 'risk', 'perspective'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS issue_tags (
    issue_id VARCHAR(255) NOT NULL,
    tag_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255), -- agent or human key id
    PRIMARY KEY (issue_id, tag_id)
);

-- Initial core tags
INSERT IGNORE INTO tags (id, kind, description) VALUES
('networking', 'topical', 'Network-related discussions and patches'),
('security', 'risk', 'Security-sensitive areas and threat modeling'),
('vouch-critical', 'governance', 'Items requiring explicit high-precision vouching'),
('nix', 'perspective', 'NixOS/Nix-specific implementation details'),
('architecture', 'perspective', 'Structural and architectural decisions');

# Tagging Schema Design (Dolt + jj)

## Context
Vaglio needs a way to organize discussions and code changes using multidimensional tags. This improves token efficiency by allowing agents to only ingest relevant parts of the history and improves discovery for human maintainers.

## Dolt Relational Layer

We will use Dolt to store the canonical relationships between issues and tags.

### Tables

#### `tags`
Stores the identity and type of tags.
- `id`: primary key, string (e.g., "networking")
- `kind`: enum ('topical', 'governance', 'risk', 'perspective')
- `description`: string, optional
- `created_at`: timestamp

#### `issue_tags`
Many-to-many relationship between issues and tags.
- `issue_id`: primary key (part 1), references `issues.id`
- `tag_id`: primary key (part 2), references `tags.id`
- `created_at`: timestamp
- `created_by`: string (agent/human key id)

## Jujutsu (jj) Mapping

`jj` will be used to track the evolution of tags in the code DAG.

### Revset Integration
We will map tags to `jj` namespaced pointers to allow discovery via revsets.
- `tags/<tag_name>`: A bookmark or tag pointer in `jj`.
- Discovery query: `jj log -r 'tag(networking)'`

### Context Pruning
The orchestrator will use the `issue_tags` table to identify relevant tags for a question and then use `jj` to retrieve the surgical history of those tags.

## Sync Strategy

1. **Protocol Event**: Retagging an issue is a first-class Vaglio protocol action.
2. **Atomic Write**: The action writes to both the Dolt database (for relational queries) and the `jj` description/metadata (for historical visibility).
3. **Derived Projections**: The WebUI and CLI use Dolt for fast listing and filtering, and `jj` for detailed history and diffs.

## Vouching Integration

Vouching will be tag-scoped.
- `vouches` table in Dolt will include a `tag_id` or `scope` field.
- Precision weighting will be calculated based on the voucher's transitive trust within that specific tag scope.

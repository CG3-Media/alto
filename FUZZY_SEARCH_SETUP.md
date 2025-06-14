# Alto Fuzzy Search Setup

Alto supports intelligent fuzzy search using PostgreSQL's trigram similarity matching or fallback to basic LIKE queries for other databases.

## PostgreSQL Setup (Recommended)

### 1. Enable pg_trgm Extension

The migration will automatically enable the extension, but if you need to do it manually:

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### 2. Run the Migration

```bash
rails db:migrate
```

This will:
- Enable the pg_trgm extension
- Add GIN indexes on title and description fields
- Create a composite index for combined search

### 3. How It Works

With pg_trgm enabled, searches like:
- `"custmer supprt"` → matches "customer support" (typo tolerance)
- `"great serv"` → matches "great service" (partial words)
- `"billing payment"` → matches "billing and payment issues" (word order flexibility)

The search uses similarity scoring:
- Title matches are weighted 2x more than descriptions
- Results are ordered by relevance score
- Falls back to LIKE queries if exact matches are needed

## Non-PostgreSQL Databases

For MySQL, SQLite, or other databases, Alto automatically falls back to case-insensitive LIKE queries:
- Still searches both title and description
- No typo tolerance
- Exact substring matching only

## Performance Considerations

- PostgreSQL with trigram indexes: Very fast, even with millions of records
- LIKE queries: Adequate for small-to-medium datasets (< 100k records)

## Testing Search

```ruby
# Fuzzy search with typos
Alto::Ticket.search("custmer isue")

# Partial word matching
Alto::Ticket.search("bill pay")

# Multi-word search
Alto::Ticket.search("great customer support")
```

## Troubleshooting

If you see errors about missing functions or operators:
1. Ensure PostgreSQL is version 9.1+ (pg_trgm included by default)
2. Check extension is enabled: `SELECT * FROM pg_extension WHERE extname = 'pg_trgm';`
3. Verify user has CREATE EXTENSION privileges

The search will automatically fall back to LIKE queries if pg_trgm is not available.

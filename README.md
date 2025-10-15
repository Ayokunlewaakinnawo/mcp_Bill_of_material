# BOM MCP Server

Tools for working with the inventory/BOM database via the Model Context Protocol.

## Prerequisites
- Docker 24+ and Docker Compose plugin
- `initdb/inventory_dump.sql` checked into the repo (already included)

## Quick Start
```bash
docker compose up --build
```

This starts two containers:
- `pg-inventory` (Postgres 16) seeded automatically from `initdb/inventory_dump.sql`
- `mcp-bom-db` (Python MCP server) connected to that database

The MCP server stays attached to STDIO, which is what Claude expects when spawning MCP tools. If you want shell access inside the container:
```bash
docker compose exec mcp bash
```

## Database Snapshot
The `initdb` directory is mounted into `/docker-entrypoint-initdb.d` for the Postgres image. Any `.sql` or `.sh` files placed here run once when the volume is first created.

To refresh the snapshot from a running database:
```bash
docker compose exec db pg_dump --format=plain --no-owner --no-privileges inventory_db > initdb/inventory_dump.sql
```

Commit the updated SQL file so collaborators get the same seed data on first boot.

## Shutdown & Cleanup
```bash
docker compose down        # stop containers
docker compose down -v     # stop containers and remove the pg_data volume
```

Removing the volume forces Postgres to re-seed from `initdb` the next time you start the stack.

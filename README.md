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

## Claude Desktop Setup
Claude looks for MCP server definitions in `~/Library/Application Support/Claude/claude_desktop_config.json`. Append (or merge) the following block so Claude can launch both the counting tool and this BOM server:

```json
{
  "mcpServers": {
    "count-r": {
      "command": "/Users/ayo/Documents/allata/Test_int/count-r-server/env/bin/python3",
      "args": [
        "/Users/ayo/Documents/allata/Test_int/count-r-server/server.py"
      ],
      "env": { "PYTHONUNBUFFERED": "1" }
    },
    "bom-db-tools": {
      "command": "/Users/ayo/Documents/allata/Test_int/count-r-server/env/bin/python3",
      "args": [
        "/Users/ayo/Documents/allata/Test_int/industrial-part/server.py"
      ],
      "env": {
        "PYTHONUNBUFFERED": "1",
        "DATABASE_URL": "postgresql+psycopg://inventory_user:supersecret@localhost:5432/inventory_db"
      }
    }
  }
}
```

Notes:
- Update the interpreter/paths if your local directory or virtual environment differs.
- The `DATABASE_URL` points at the Postgres container published on port `5432`; ensure `docker compose up` is running before starting Claude.
- Restart Claude Desktop after editing the config so it reloads the MCP server list.
- Inside Claude Desktop you can jump straight to the config via *Settings → Developer → Open config file*, which opens `claude_desktop_config.json` in your default editor.

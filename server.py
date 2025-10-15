from mcp.server.fastmcp import FastMCP
import logging, sys, os
from sqlalchemy import create_engine, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.pool import QueuePool

# ---- logging to STDERR only (stdout reserved for JSON-RPC) ----
logging.basicConfig(stream=sys.stderr, level=logging.INFO, format="%(levelname)s: %(message)s")

# ---- DB engine (Postgres) ----
DATABASE_URL = os.getenv("DATABASE_URL")  # e.g. postgresql+psycopg://inventory_user:supersecret@localhost:5432/inventory_db
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL env var is required")

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=5,
    max_overflow=2,
    pool_pre_ping=True,
    future=True,
)

# ---- MCP server over stdio ----
mcp = FastMCP(name="bom-db-tools")

@mcp.tool()
def get_item_description(part_number: str) -> str:
    """
    Return the description for the given item part number.
    Example: get_item_description("ABC123") -> "Power Supply Board"
    """
    pn = (part_number or "").strip()
    if not pn:
        return "Missing part_number"

    try:
        with engine.connect() as conn:
            row = conn.execute(
                text("SELECT description FROM items WHERE part_number ILIKE :pn"),
                {"pn": pn},
            ).mappings().first()
        return row["description"] if row and row.get("description") else "Item not found"
    except Exception:
        logging.exception("DB query failed")
        return "Error while fetching item"

@mcp.tool()
def find_items_by_description_ft(query: str, limit: int = 25):
    """
    Full-text search on descriptions.
    Example: find_items_by_description_ft("power supply board")
    """
    q = (query or "").strip()
    if not q:
        return []

    sql = """
    SELECT part_number, description
    FROM items
    WHERE to_tsvector('english', description) @@ plainto_tsquery('english', :q)
    ORDER BY part_number
    LIMIT :limit;
    """

    try:
        with engine.connect() as conn:
            rows = conn.execute(text(sql), {"q": q, "limit": limit}).mappings().all()
            return [dict(r) for r in rows]
    except Exception:
        logging.exception("find_items_by_description_ft failed")
        return []

@mcp.tool()
def bom_for_item(part_number: str):
    """
    Return the component-level BOM for a parent item part number (case-insensitive).
    Each row includes parent PN, component PN, description, and optional notes.
    """
    pn = (part_number or "").strip()
    if not pn:
        return []

    sql = """
    SELECT
      parent.part_number   AS parent_part_number,
      comp.part_number     AS component_part_number,
      comp.description     AS component_description,
      b.notes
    FROM items parent
    JOIN bom   b   ON b.parent_item_id   = parent.id
    JOIN items comp ON comp.id           = b.component_item_id
    WHERE upper(parent.part_number) = upper(:pn)
    ORDER BY comp.part_number;
    """

    try:
        with engine.connect() as conn:
            rows = conn.execute(text(sql), {"pn": pn}).mappings().all()
            return [dict(r) for r in rows]
    except Exception:
        logging.exception("bom_for_item failed")
        return []

@mcp.tool()
def items_with_component(component_part_number: str):
    """
    List parent items that include the given component part number (case-insensitive).
    Example: items_with_component("T8140")
    Returns: [{"parent_part_number": "...", "parent_description": "..."}...]
    """
    cpn = (component_part_number or "").strip()
    if not cpn:
        return []

    sql = """
    SELECT DISTINCT
      parent.part_number AS parent_part_number,
      parent.description AS parent_description
    FROM items comp
    JOIN bom   b      ON b.component_item_id = comp.id
    JOIN items parent ON parent.id           = b.parent_item_id
    WHERE upper(comp.part_number) = upper(:cpn)
    ORDER BY parent.part_number;
    """
    try:
        with engine.connect() as conn:
            rows = conn.execute(text(sql), {"cpn": cpn}).mappings().all()
            return [dict(r) for r in rows]
    except Exception:
        logging.exception("items_with_component failed")
        return []

@mcp.tool()
def create_item(part_number: str, description: str = ""):
    """
    Insert a new item into the items table. Returns the inserted row metadata.
    """
    pn = (part_number or "").strip()
    if not pn:
        return {"status": "error", "message": "part_number is required"}

    desc_clean = (description or "").strip()
    desc_db = desc_clean if desc_clean else None

    try:
        with engine.begin() as conn:
            existing = conn.execute(
                text("SELECT id, description FROM items WHERE upper(part_number) = upper(:pn)"),
                {"pn": pn},
            ).mappings().first()
            if existing:
                return {
                    "status": "exists",
                    "message": "Item already exists",
                    "item_id": existing["id"],
                    "part_number": pn,
                    "description": existing.get("description") or "",
                }

            result = conn.execute(
                text(
                    "INSERT INTO items (part_number, description) VALUES (:pn, :desc) RETURNING id"
                ),
                {"pn": pn, "desc": desc_db},
            )
            new_id = result.scalar_one()
        return {
            "status": "ok",
            "item_id": new_id,
            "part_number": pn,
            "description": desc_clean,
        }
    except IntegrityError as exc:
        logging.warning("create_item integrity error for %s: %s", pn, exc)
        return {"status": "error", "message": "Item already exists"}
    except Exception:
        logging.exception("create_item failed")
        return {"status": "error", "message": "Failed to insert item"}

@mcp.tool()
def add_bom_component(parent_part_number: str, component_part_number: str, notes: str = ""):
    """
    Insert a BOM relationship between an existing parent and component item.
    """
    parent_pn = (parent_part_number or "").strip()
    component_pn = (component_part_number or "").strip()
    if not parent_pn or not component_pn:
        return {
            "status": "error",
            "message": "parent_part_number and component_part_number are required",
        }
    if parent_pn.upper() == component_pn.upper():
        return {
            "status": "error",
            "message": "Parent and component cannot be the same item",
        }

    notes_clean = (notes or "").strip()
    notes_db = notes_clean if notes_clean else None

    try:
        with engine.begin() as conn:
            parent_row = conn.execute(
                text("SELECT id FROM items WHERE upper(part_number) = upper(:pn)"),
                {"pn": parent_pn},
            ).mappings().first()
            if not parent_row:
                return {"status": "error", "message": f"Parent item '{parent_pn}' not found"}

            component_row = conn.execute(
                text("SELECT id FROM items WHERE upper(part_number) = upper(:pn)"),
                {"pn": component_pn},
            ).mappings().first()
            if not component_row:
                return {"status": "error", "message": f"Component item '{component_pn}' not found"}

            existing = conn.execute(
                text(
                    "SELECT id FROM bom WHERE parent_item_id = :parent_id AND component_item_id = :component_id"
                ),
                {"parent_id": parent_row["id"], "component_id": component_row["id"]},
            ).scalar()
            if existing:
                return {
                    "status": "exists",
                    "message": "BOM entry already exists",
                    "bom_id": existing,
                    "parent_part_number": parent_pn,
                    "component_part_number": component_pn,
                }

            result = conn.execute(
                text(
                    "INSERT INTO bom (parent_item_id, component_item_id, notes) "
                    "VALUES (:parent_id, :component_id, :notes) RETURNING id"
                ),
                {
                    "parent_id": parent_row["id"],
                    "component_id": component_row["id"],
                    "notes": notes_db,
                },
            )
            bom_id = result.scalar_one()

        return {
            "status": "ok",
            "bom_id": bom_id,
            "parent_part_number": parent_pn,
            "component_part_number": component_pn,
            "notes": notes_clean,
        }
    except IntegrityError as exc:
        logging.warning(
            "add_bom_component integrity error for parent=%s component=%s: %s",
            parent_pn,
            component_pn,
            exc,
        )
        return {"status": "error", "message": "Database rejected BOM entry"}
    except Exception:
        logging.exception("add_bom_component failed")
        return {"status": "error", "message": "Failed to insert BOM entry"}

if __name__ == "__main__":
    logging.info("Starting MCP server (stdio, Postgres-backed)")
    mcp.run()

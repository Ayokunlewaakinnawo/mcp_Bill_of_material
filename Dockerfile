FROM python:3.11-slim

# Keep image small & IO correct for MCP
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create non-root user
RUN useradd -m appuser
WORKDIR /app

# Install Python deps first (layer cache friendly)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy server + (optionally) SQL files for reference
COPY server.py .
COPY initdb ./initdb

# Drop privileges
USER appuser

# MCP over stdio
ENTRYPOINT ["python", "server.py"]
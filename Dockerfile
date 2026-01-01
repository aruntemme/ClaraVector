FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libxml2-dev \
    libxslt-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/
COPY scripts/ ./scripts/

# Create data directories
RUN mkdir -p /app/data/sqlite /app/data/lancedb /app/data/files /app/logs

# Expose port (Railway will use PORT env var)
EXPOSE 8000

# Note: Railway performs its own healthcheck, Docker HEALTHCHECK is for local dev only
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import httpx; import os; httpx.get(f'http://localhost:{os.environ.get(\"PORT\", 8000)}/api/v1/health/live', timeout=5)"

# Run the application - use shell form to expand PORT env var (Railway requirement)
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}

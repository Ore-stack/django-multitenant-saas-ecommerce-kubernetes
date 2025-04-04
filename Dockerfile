# Use an official Python runtime as a parent image
FROM python:3.11-slim-bullseye AS build

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/venv/bin:$PATH"

# Install system dependencies
RUN apt-get update && apt-get install -y curl gcc libpq-dev && rm -rf /var/lib/apt/lists/*

# Create app user and app directory
RUN useradd -m appuser && mkdir -p /app
WORKDIR /app

# Copy only requirement files first for caching
COPY --chown=appuser:appuser requirements.txt /app/

# Create virtual environment and install Python deps
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir --upgrade pip setuptools && \
    /app/venv/bin/pip install --no-cache-dir -r requirements.txt

# Copy the rest of the codebase
COPY --chown=appuser:appuser . /app/

# Set appropriate permissions
RUN chown -R appuser:appuser /app && \
    find /app -type d -exec chmod 750 {} \; && \
    find /app -type f -exec chmod 640 {} \; && \
    chmod +x /app/manage.py && \
    chmod 750 /app/venv/bin/python

# Switch to non-root user
USER appuser

# Expose necessary ports
EXPOSE 8000 80 8585

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default command
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "wsgi:application"]

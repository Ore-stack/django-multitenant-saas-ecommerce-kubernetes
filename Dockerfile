# Use an official Python runtime as a parent image
FROM python:3.11-slim-bullseye as build

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PATH="/app/venv/bin:$PATH"

# Create user and directory structure first
RUN useradd -m appuser && \
    mkdir -p /app && \
    chown appuser:appuser /app

WORKDIR /app

# Copy files with correct ownership in one layer
COPY --chown=appuser:appuser requirements.txt manage.py .env /app/
COPY --chown=appuser:appuser apps /app/apps/
COPY --chown=appuser:appuser media /app/media/
COPY --chown=appuser:appuser multitenantsaas /app/multitenantsaas/
COPY --chown=appuser:appuser tests /app/tests/

# Create and activate virtual environment
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --upgrade pip setuptools && \
    /app/venv/bin/pip install -r requirements.txt

# Copy remaining files (if any) with proper permissions
COPY --chown=appuser:appuser . /app/

# Set directory permissions (more secure than 755)
RUN find /app -type d -exec chmod 750 {} \; && \
    find /app -type f -exec chmod 640 {} \; && \
    chmod 750 /app/venv/bin/python

# Special permissions for test files if needed
RUN if [ -d "/app/tests" ]; then \
        find /app/tests -type f -exec chmod 750 {} \; && \
        find /app/tests -type d -exec chmod 755 {} \;; \
    fi

# Switch to non-root user
USER appuser

# Expose ports
EXPOSE 8585 8000 80

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Set the default command to run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "wsgi:application"]

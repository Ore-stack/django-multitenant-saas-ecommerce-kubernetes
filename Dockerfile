# Use an official Python runtime as a parent image
FROM python:3.11-slim-bullseye AS build

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PATH="/app/venv/bin:$PATH"

# Create user and set up working directory
RUN useradd -m appuser && mkdir -p /app

WORKDIR /app

# Copy files with proper ownership
COPY --chown=appuser:appuser requirements.txt manage.py .env /app/
COPY --chown=appuser:appuser apps media multitenantsaas tests /app/

# Create virtual environment and install dependencies
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir --upgrade pip setuptools && \
    /app/venv/bin/pip install --no-cache-dir -r requirements.txt

# Ensure correct permissions
RUN chown -R appuser:appuser /app && \
    find /app -type d -exec chmod 750 {} \; && \
    find /app -type f -exec chmod 640 {} \;

# Allow execution for necessary files
RUN chmod +x /app/manage.py && \
    chmod 750 /app/venv/bin/python

# Expose necessary ports
EXPOSE 8000 80 8585

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Switch to non-root user
USER appuser

# Start the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "wsgi:application"]

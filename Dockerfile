# Use an official Python runtime as a parent image
FROM python:3.11-slim-bullseye as build

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file and essential directories into the container
COPY requirements.txt /app/
COPY apps /app/
COPY media /app/
COPY multitenantsaas /app/
COPY tests /app/
COPY .env /app/
COPY manage.py /app/

# Create a new user, assign ownership of the /app directory, and set correct permissions
RUN useradd -m appuser && \
    chown -R appuser:appuser /app && \
    chmod -R 777 /app  # Grant write permissions

# Switch to the non-root user to run the application
USER appuser

# Create and activate a virtual environment
RUN python3 -m venv /app/venv

# Install pip and setuptools inside the virtual environment
RUN /app/venv/bin/pip install --upgrade pip setuptools

# Install dependencies in the virtual environment
RUN /app/venv/bin/pip install -r requirements.txt

# Set PATH to use the virtual environment
ENV PATH="/app/venv/bin:$PATH"

# Expose the required ports
EXPOSE 8585
EXPOSE 8000
EXPOSE 80

# Set the default command to run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "wsgi:application"]

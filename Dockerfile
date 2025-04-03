# Use an official Python runtime as a parent image
FROM python:3.11-slim-bullseye as build

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirements.txt /app/
COPY apps /app/
COPY media /app/
COPY multitenantsaas /app/
COPY tests /app/
COPY .env /app/
COPY manage.py /app/

# Create a virtual environment
RUN python3 -m venv /app/venv

# Upgrade pip and setuptools inside the virtual environment
RUN /app/venv/bin/pip install --upgrade pip setuptools

# Install dependencies inside the virtual environment
RUN /app/venv/bin/pip install -r requirements.txt

# Set PATH to use the virtual environment
ENV PATH="/app/venv/bin:$PATH"

# Copy the rest of the application code into the container
COPY . /app/

# Expose necessary ports
EXPOSE 8585
EXPOSE 8000
EXPOSE 80

# Define the default command to run the app (if needed)
# CMD ["python", "manage.py", "runserver", "0.0.0.0:8585"]

# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install system dependencies for FFmpeg and OpenCV
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend code into the container
COPY . .

# Expose port (Railway dynamically injects $PORT, but we set a default)
ENV PORT=8000
EXPOSE $PORT

# Start the FastAPI app using Uvicorn
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}

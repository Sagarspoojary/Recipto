FROM python:3.10-slim

# Install system dependencies (including tesseract-ocr)
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Render exposes PORT environment variable, uvicorn will bind to it
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}

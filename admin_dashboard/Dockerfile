FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        default-libmysqlclient-dev \
        pkg-config \
        build-essential \
        libffi-dev \
        libssl-dev \
        python3-dev \
        curl \
        && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install wheel
RUN pip install --upgrade pip setuptools wheel

# Install Python dependencies
COPY requirements.txt .

# Install dependencies with increased timeout and retries
RUN pip install --no-cache-dir --timeout=1000 --retries=5 -r requirements.txt

# Copy project
COPY . .

# Expose port
EXPOSE 8501

# Run the application
CMD ["streamlit", "run", "main.py", "--server.port=8501", "--server.address=0.0.0.0"]
